# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kymera/version'

Gem::Specification.new do |spec|
  spec.name          = "kymera"
  spec.version       = Kymera::VERSION
  spec.authors       = ["jakesa"]
  spec.email         = ["jakes55214@yahoo.com"]
  spec.description   = 'Execute cucumber tests in parallel'
  spec.summary       = 'Execute cucumber tests in parallel'
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_dependency 'cucumber'
  spec.add_dependency 'dcell'
  spec.add_dependency 'celluloid'

end
