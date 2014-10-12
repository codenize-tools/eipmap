class Eipmap::Client
  def initialize(options = {})
    @options = options
    @ec2 = Aws::EC2::Client.new
  end

  def export(options = {})
    options = @options.merge(options)
    exported = Eipmap::Exporter.export(@ec2, options)
    Eipmap::DSL.convert(exported, options)
  end
end
