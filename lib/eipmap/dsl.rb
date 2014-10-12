class Eipmap::DSL
  def self.convert(exported, options = {})
    Eipmap::DSL::Converter.convert(exported, options)
  end

  def self.parse(dsl, path, opts = {})
    # XXX:
  end
end
