class Eipmap::DSL
  def self.convert(exported, options = {})
    Eipmap::DSL::Converter.convert(exported, options)
  end

  def self.parse(dsl, path, options = {})
    Eipmap::DSL::Context.eval(dsl, path, options).result
  end
end
