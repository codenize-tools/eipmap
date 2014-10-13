if ENV['TRAVIS']
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec/"
  end
end

require 'erb'
require 'tempfile'
require 'eipmap'

# Amazon Linux AMI 2014.09 (HVM)
TEST_IMAGE_ID = 'ami-d6e1c584'

Aws.config.update(
  access_key_id: ENV['EIPMAP_TEST_ACCESS_KEY_ID'],
  secret_access_key: ENV['EIPMAP_TEST_AWS_SECRET_ACCESS_KEY'],
  region: ENV['EIPMAP_TEST_AWS_REGION'])

$ec2 = Aws::EC2::Client.new

def run_instances(n)
  resp = $ec2.run_instances(
    image_id: TEST_IMAGE_ID,
    min_count: n,
    max_count: n,
    instance_type: 't2.micro',
    network_interfaces: [{
      device_index: 0,
      associate_public_ip_address: false}])

  instance_ids = resp.instances.map(&:instance_id)
  $ec2.wait_until(:instance_running, instance_ids: instance_ids)
  $test_instances = resp.instances
end

def terminate_instances
  instance_ids = $test_instances.map(&:instance_id)
  $ec2.terminate_instances(instance_ids: instance_ids)
  $ec2.wait_until(:instance_terminated, instance_ids: instance_ids)
end

def allocate_addresses(n)
  $test_addresses = (1..n).map do
    $ec2.allocate_address(domain: 'vpc')
  end
end

def release_addresses
  allocation_ids = $test_addresses.map(&:allocation_id)

  allocation_ids.each do |allocation_id|
    $ec2.release_address(allocation_id: allocation_id)
  end
end

def disassociate_addresses
  allocation_ids = $test_addresses.map(&:allocation_id)
  resp = $ec2.describe_addresses(allocation_ids: allocation_ids)
  association_ids = resp.addresses.map(&:association_id)

  association_ids.each do |association_id|
    next unless association_id
    $ec2.disassociate_address(association_id: association_id)
  end
end

def describe_network_interface
  result = {}

  $test_instances.each do |instance|
    interface = instance.network_interfaces.first
    interface_id = interface.network_interface_id
    result[interface_id] = []

    interface.private_ip_addresses.sort_by {|address|
      address.primary ? '' : address.private_ip_address
    }.each {|address|
      result[interface_id] << address.private_ip_address
    }
  end

  result
end

def describe_addresses
  result = {}

  $ec2.describe_addresses.each do |resp|
    resp.addresses.each do |address|
      domain = address.domain
      public_ip = address.public_ip
      result[domain] ||= {}
      result[domain][public_ip] = {}

      [:network_interface_id, :private_ip_address].each do |key|
        value = address[key] || ''
        result[domain][public_ip][key] = value unless value.empty?
      end
    end
  end

  result
end

def client(user_options = {})
  options = {logger: Logger.new('/dev/null')}

  if_debug do
    logger = Eipmap::Logger.instance
    logger.set_debug(true)
    options.update(
      debug: true,
      logger: logger,
      aws_config: {
        http_wire_trace: true,
        logger: logger})
  end

  options = options.merge(user_options)
  Eipmap::Client.new(options)
end

def tempfile(content, options = {})
  basename = "#{File.basename __FILE__}.#{$$}"
  basename = [basename, options[:ext]] if options[:ext]

  Tempfile.open(basename) do |f|
    f.puts(content)
    f.flush
    f.rewind
    yield(f)
  end
end

def apply(cli = client)
  elbfile = yield
  elbfile = ERB.new(elbfile, nil, '-').result(binding)

  if_debug do
    puts <<-EOS
--- ELBfile ---
#{elbfile.strip}
---------------
    EOS
  end

  tempfile(elbfile) do |f|
    cli.apply(f.path)
  end
end

def if_debug
  if ENV['DEBUG'] == '1'
    yield
  end
end

RSpec.configure do |config|
  config.before(:all) do
    run_instances(3)
    allocate_addresses(3)
  end

  config.before(:each) do
    disassociate_addresses
  end

  config.after(:all) do
    terminate_instances
    release_addresses
  end
end
