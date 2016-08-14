# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'exact_target_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'exact-target-client'
  spec.version       = ExactTargetClient::VERSION
  spec.authors       = ['Ariel Cabib', 'Yaron Dinur']
  spec.email         = ['acabib@yotpo.com', 'ydinur@yotpo.com']

  spec.summary       = 'Ruby client for interacting with ExactTarget (Salesforce Marketing Cloud) APIs'
  spec.description   = 'Ruby client for interacting with ExactTarget (Salesforce Marketing Cloud) APIs'
  spec.homepage      = 'https://github.com/YotpoLtd/exact-target-ruby-api'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'savon', '2.3.3'
  spec.add_runtime_dependency 'typhoeus'
  spec.add_runtime_dependency 'oj'
end
