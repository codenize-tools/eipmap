class Eipmap::DSL::Context::Domain
  def initialize(domain, &block)
    @domain = domain
    @result = {}
    instance_eval(&block)
  end

  attr_reader :result

  private

  def ip(ip_address, options = {})
    if @result[ip_address]
      raise "Domain `#{@domain}`: IP `#{ip_address}` is already defined"
    end

    @result[ip_address] = options
  end
end
