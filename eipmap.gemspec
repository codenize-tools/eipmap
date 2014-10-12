# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'eipmap/version'

Gem::Specification.new do |spec|
  spec.name          = 'eipmap'
  spec.version       = Eipmap::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sgwr_dts@yahoo.co.jp']
  spec.summary       = %q{Eipmap is a tool to manage Elastic IP Addresses (EIP).}
  spec.description   = %q{Eipmap is a tool to manage Elastic IP Addresses (EIP). It defines the state of EIP using DSL, and updates EIP according to DSL.}
  spec.homepage      = 'https://github.com/winebarrel/eipmap'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-core', '~> 2.0.2'
  spec.add_dependency "term-ansicolor"
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
end
