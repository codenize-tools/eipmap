class Eipmap::DSL::Context::Domain
  def initialize(domain, &block)
    @domain = domain
    @result = {}
    instance_eval(&block)
  end

  attr_reader :result

  private

  def ip(ip_address, options = {})
    ip_address = ip_address.to_s

    if @result[ip_address]
      raise "#{@domain} > #{ip_address}: already defined"
    end

    @result[ip_address] = options
  end
end
