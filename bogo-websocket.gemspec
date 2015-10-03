$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'bogo-websocket/version'
Gem::Specification.new do |s|
  s.name = 'bogo-websocket'
  s.version = Bogo::Websocket::VERSION.version
  s.summary = 'Simple websocket libraries'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'https://github.com/spox/bogo-websocket'
  s.description = 'Simple websocket libraries'
  s.require_path = 'lib'
  s.license = 'Apache 2.0'
  s.add_runtime_dependency 'bogo', '>= 0.1.30', '< 1.0.0'
  s.add_runtime_dependency 'websocket', '~> 1.2.2'
  s.add_development_dependency 'minitest'
  s.files = Dir['lib/**/*'] + %w(bogo-websocket.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
