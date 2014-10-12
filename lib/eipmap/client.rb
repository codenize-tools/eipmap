class Eipmap::Client
  def initialize(options = {})
    @options = options
    @ec2 = Aws::EC2::Client.new
    @driver = Eipmap::Driver.new(@ec2, options)
  end

  def export
    exported = Eipmap::Exporter.export(@ec2, @options)
    Eipmap::DSL.convert(exported, @options)
  end

  def apply(file)
    walk(file)
  end

  private

  def walk(file)
    expected = load_file(file)
    actual = Eipmap::Exporter.export(@ec2, @options)
    updated = false

    expected.each do |domain, expected_ips|
      actual_ips = actual.delete(domain)

      if actual_ips
        result = walk_ips(domain, expected_ips, actual_ips)
        updated ||= result
      else
        # XXX: output warning "IP addresses that are not allocated are defined"
      end
    end

    actual.each do |domain, ips|
      # XXX: output warning "undefined IP address exist"
    end

    updated
  end

  def walk_ips(domain, expected_ips, actual_ips)
    updated = false

    expected_ips.sort_by {|k, v| v.length }.each do |ip, expected_attrs|
      actual_attrs = actual_ips.delete(ip)

      if actual_attrs
        result = walk_ip(domain, ip, expected_attrs, actual_attrs)
        updated ||= result
      else
        # XXX: output warning "IP addresses that are not allocated are defined"
      end
    end

    actual_ips.each do |ip, attrs|
      # XXX: output warning "undefined IP address exist"
    end

    updated
  end

  def walk_ip(domain, ip, expected_attrs, actual_attrs)
    return false if association_is_equal?(expected_attrs, actual_attrs)
    @driver.update_association(domain, ip, expected_attrs, actual_attrs)
  end

  def association_is_equal?(expected_attrs, actual_attrs)
    if expected_attrs[:network_interface_id]
      result = (expected_attrs[:network_interface_id] == actual_attrs[:network_interface_id])

      if expected_attrs[:private_ip_address]
        result &= (expected_attrs[:private_ip_address] == actual_attrs[:private_ip_address])
      end

      result
    elsif expected_attrs[:instance_id]
      expected_attrs[:instance_id] == actual_attrs[:instance_id]
    else
      not actual_attrs[:network_interface_id] and not actual_attrs[:instance_id]
    end
  end

  def load_file(file)
    if file.kind_of?(String)
      open(file) do |f|
        Eipmap::DSL.parse(f.read, file)
      end
    elsif file.respond_to?(:read)
      Eipmap::DSL.parse(file.read, file.path)
    else
      raise TypeError, "can't convert #{file} into File"
    end
  end
end
