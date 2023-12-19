# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'omniauth/microsoft_graph/version'

Gem::Specification.new do |spec|
  spec.name          = "omniauth-microsoft_graph"
  spec.version       = OmniAuth::MicrosoftGraph::VERSION
  spec.authors       = ["Peter Philips", "Joel Van Horn"]
  spec.email         = ["pete@p373.net", "joel@joelvanhorn.com"]
  spec.summary       = %q{omniauth provider for Microsoft Graph}
  spec.description   = %q{omniauth provider for new Microsoft Graph API}
  spec.homepage      = "https://github.com/synth/omniauth-microsoft_graph"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'jwt', '>= 2.0'
  spec.add_runtime_dependency 'omniauth', '~> 2.0'
  spec.add_runtime_dependency 'omniauth-oauth2', '~> 1.8.0'
  spec.add_development_dependency "sinatra", '~> 0'
  spec.add_development_dependency "rake", '~> 12.3.3', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency "mocha", '~> 0'
end
