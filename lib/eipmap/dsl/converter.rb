class Eipmap::DSL::Converter
  def self.convert(exported, options = {})
    self.new(exported, options).convert
  end

  def initialize(exported, options = {})
    @exported = exported
    @options = options
    @instance_names = options[:instance_names] || {}
  end

  def convert
    output_domains(@exported)
  end

  private

  def output_domains(domains)
    domains.each.sort_by {|k, v| k }.map {|domain, ips|
      output_domain(domain, ips)
    }.join("\n")
  end

  def output_domain(domain, ips)
    return nil if ips.empty?

    <<-EOS
domain #{domain.inspect} do
  #{output_ips(ips)}
end
    EOS
  end

  def output_ips(ips)
    ips.sort_by {|k, v| [@instance_names[v[:instance_id]], IPAddr.new(k).to_i].to_s }.map {|ip, attrs|
      output_ip(ip, attrs)
    }.join.strip
  end

  def output_ip(ip, attrs)
    args = [ip.inspect]
    ip_options = {}

    if attrs[:network_interface_id]
      ip_options[:network_interface_id] = attrs[:network_interface_id]
    elsif attrs[:instance_id]
      ip_options[:instance_id] = attrs[:instance_id]
    end

    if attrs[:private_ip_address]
      ip_options[:private_ip_address] = attrs[:private_ip_address]
    end

    unless ip_options.empty?
      args << ip_options.inspect.sub(/\A\{/, '').sub(/\}\z/, '')
    end

    instance_id = attrs[:instance_id]
    instance_name = @instance_names[instance_id]

    comment = instance_name ? (<<-EOS) : ''
  # #{instance_name} #{instance_id}
    EOS

    comment + (<<-EOS)
  ip #{args.join(', ')}
    EOS
  end
end
