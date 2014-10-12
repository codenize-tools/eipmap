require 'logger'
require 'singleton'

require 'aws-sdk-core'
require 'term/ansicolor'

module Eipmap; end
require 'eipmap/logger'
require 'eipmap/client'
require 'eipmap/driver'
require 'eipmap/dsl'
require 'eipmap/dsl/context'
require 'eipmap/dsl/context/domain'
require 'eipmap/dsl/converter'
require 'eipmap/exporter'
require 'eipmap/ext/string_ext'
require 'eipmap/version'
