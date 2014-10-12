class Eipmap::Exporter
  def self.export(ec2, options = {})
    self.new(ec2, options).export
  end

  def initialize(ec2, options = {})
    @ec2 = ec2
    @options = options
  end

  def export
    result = {}

    @ec2.describe_addresses.each do |response|
      response.addresses.each do |address|
        export_address(address, result)
      end
    end

    return result
  end

  private

  def export_address(address, result)
    domain = address.domain
    public_ip = address.public_ip
    result[domain] ||= {}
    result[domain][public_ip] = {}

    [
      :instance_id,
      :allocation_id,
      :association_id,
      :network_interface_id,
      :private_ip_address,
    ].each do |key|
      value = empty_to_nil(address[key])
      result[domain][public_ip][key] = value if value
    end
  end

  def empty_to_nil(str)
    if str.nil? or str.empty?
      nil
    else
      str
    end
  end
end
