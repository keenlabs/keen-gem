# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "keen/version"

Gem::Specification.new do |s|
  s.name        = "keen"
  s.version     = Keen::VERSION
  s.authors     = ["Alex Kleissner", "Joe Wegner"]
  s.email       = "opensource@keen.io"
  s.homepage    = "https://github.com/keenlabs/keen-gem"
  s.summary     = "Keen IO API Client"
  s.description = "Send events and build analytics features into your Ruby applications."
  s.license     = "MIT"

  s.add_dependency "multi_json", "~> 1.12"
  s.add_dependency "addressable", "~> 2.5"

  s.add_dependency 'rubysl', '~> 2.0' if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'

  # guard
  s.add_development_dependency 'guard', '~> 2.14'
  s.add_development_dependency 'guard-rspec', '~> 4.7'

  # guard cross-platform listener trick
  s.add_development_dependency 'rb-inotify', '~> 0.9'
  s.add_development_dependency 'rb-fsevent', '~> 0.9'
  s.add_development_dependency 'rb-fchange', '~> 0.0.6'

  # guard notifications
  s.add_development_dependency 'ruby_gntp', '~> 0.3'

  # fix guard prompt
  s.add_development_dependency 'rb-readline', '~> 0.5' # or compile ruby w/ readline

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
