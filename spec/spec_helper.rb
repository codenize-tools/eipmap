require 'eipmap'

# Ubuntu Server 14.04 LTS (HVM), SSD Volume Type
TEST_IMAGE_ID = 'ami-d6e7c084'

$ec2 = Aws::EC2::Client.new(
  access_key_id: ENV['EIPMAP_TEST_ACCESS_KEY_ID'],
  secret_access_key: ENV['EIPMAP_TEST_AWS_SECRET_ACCESS_KEY'],
  region: ENV['EIPMAP_TEST_AWS_REGION'])

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
  $test_instance_ids = instance_ids
end

def terminate_instances(instance_ids)
  return unless $test_instance_ids
  $ec2.terminate_instances(instance_ids: instance_ids)
  $ec2.wait_until(:instance_terminated, instance_ids: instance_ids)
end

def allocate_addresses(n)
  $test_addresses = (1..n).map do
    $ec2.allocate_address(domain: 'vpc')
  end
end

def release_addresses(allocation_ids)
  return unless $test_addresses
  allocation_ids = $test_addresses.map(&:allocation_id)

  allocation_ids.each do |allocation_id|
    $ec2.release_address(allocation_id: allocation_id)
  end
end

def disassociate_addresses
  return unless $test_addresses
  allocation_ids = $test_addresses.map(&:allocation_id)
  resp = $ec2.describe_addresses(allocation_ids: allocation_ids)
  association_ids = resp.addresses.map(&:association_id)

  association_ids.each do |association_id|
    next unless association_id
    $ec2.disassociate_address(association_id: association_id)
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
