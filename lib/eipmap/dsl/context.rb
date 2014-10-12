class Eipmap::DSL::Context
  def self.eval(dsl, path, options = {})
    self.new(path, options) {
      eval(dsl, binding, path)
    }
  end

  attr_reader :result

  def initialize(path, options = {}, &block)
    @path = path
    @options = options
    @result = {}
    instance_eval(&block)
  end

  private

  def require(file)
    eipfile = (file =~ %r|\A/|) ? file : File.expand_path(File.join(File.dirname(@path), file))

    if File.exist?(eipfile)
      instance_eval(File.read(eipfile), eipfile)
    elsif File.exist?(eipfile + '.rb')
      instance_eval(File.read(eipfile + '.rb'), eipfile + '.rb')
    else
      Kernel.require(file)
    end
  end

  def domain(name, &block)
    @result[name] ||= {}

    Eipmap::DSL::Context::Domain.new(name, &block).result.each do |ip, attrs|
      if @result[name][ip]
        raise "Domain `#{name}`: IP `#{ip}` is already defined"
      end

      @result[name][ip] = attrs
    end
  end
end
