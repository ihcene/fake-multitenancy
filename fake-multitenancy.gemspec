# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fake/multitenancy/version'

Gem::Specification.new do |spec|
  spec.name          = "fake-multitenancy"
  spec.version       = Fake::Multitenancy::VERSION
  spec.authors       = ["Ihcène Medjber"]
  spec.email         = ["ihcene@aritylabs.com"]

  spec.summary       = %q{Serve several clients with one single database.}
  spec.description   = %q{Serve several clients with one single database with incremental and secure ids by tenant.}
  spec.homepage      = "http://github.com/ihcene/fake-multitenancy"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", "~> 4.2"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec', '~> 3.2', '>= 3.2.0'
  spec.add_development_dependency 'sqlite3', '~> 1.3'
end
