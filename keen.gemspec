# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "keen/version"

Gem::Specification.new do |s|
  s.name        = "keen"
  s.version     = Keen::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Kyle Wild", "Josh Dzielak"]
  s.email       = "josh@keen.io"
  s.homepage    = "https://github.com/keenlabs/keen-gem"
  s.summary     = "Keen IO API Client"
  s.description = "Batch and send events to the Keen IO API. Supports asychronous requests."

  s.add_dependency "multi_json", "~> 1.0"
  s.add_dependency "jruby-openssl" if defined?(JRUBY_VERSION)

  s.add_development_dependency 'oj'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rack'
  s.add_development_dependency 'rake'
  s.add_development_dependency "em-http-request"
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'ruby_gntp'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
