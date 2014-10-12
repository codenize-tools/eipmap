class Eipmap::Driver
  include Eipmap::Logger::Helper

  def initialize(ec2, options = {})
    @ec2 = ec2
    @options = options
  end

  def update_association(domain, ip, expected_attrs, actual_attrs)
    if expected_attrs[:network_interface_id] or expected_attrs[:instance_id]
      associate_address(domain, ip, expected_attrs, actual_attrs)
    else
      disassociate_address(domain, ip, expected_attrs, actual_attrs)
    end
  end

  private

  def associate_address(domain, ip, expected_attrs, actual_attrs)
    params = {:dry_run => @options[:dry_run]}
    log_info = {}

    if (interface_id = expected_attrs[:network_interface_id])
      params[:network_interface_id] = interface_id
      log_info[:network_interface_id] = interface_id
      params[:allocation_id] = actual_attrs[:allocation_id]
      params[:allow_reassociation] = @options[:allow_reassociation]

      if (private_ip = expected_attrs[:private_ip_address])
        params[:private_ip_address] = private_ip
        log_info[:private_ip_address] = private_ip
      end
    else
      params[:public_ip] = ip
      instance_id = expected_attrs[:instance_id]
      params[:instance_id] = instance_id
      log_info[:instance_id] = instance_id
    end

    log(:info, "#{domain} > #{ip}: Associate to #{log_info.inspect}", :color => :green)

    unless_dry_run do
      @ec2.associate_address(params)
    end
  end

  def disassociate_address(domain, ip, expected_attrs, actual_attrs)
    params = {:dry_run => @options[:dry_run]}

    if actual_attrs[:association_id]
      params[:association_id] = actual_attrs[:association_id]
    else
      params[:public_ip] = ip
    end

    log(:info, "#{domain} > #{ip}: Dissociate", :color => :red)

    unless_dry_run do
      @ec2.disassociate_address(params)
    end
  end

  def unless_dry_run
    if @options[:dry_run]
      false
    else
      yield
      true
    end
  end
end
