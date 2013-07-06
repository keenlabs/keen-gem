# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "keen/version"

Gem::Specification.new do |s|
  s.name        = "keen"
  s.version     = Keen::VERSION
  s.authors     = ["Kyle Wild", "Josh Dzielak", "Daniel Kador"]
  s.email       = "josh@keen.io"
  s.homepage    = "https://github.com/keenlabs/keen-gem"
  s.summary     = "Keen IO API Client"
  s.description = "Send events and build analytics features into your Ruby applications."

  s.add_dependency "multi_json", "~> 1.0"
  s.add_dependency "jruby-openssl" if defined?(JRUBY_VERSION)

  # guard
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'

  # guard cross-platform listener trick
  s.add_development_dependency 'rb-inotify'
  s.add_development_dependency 'rb-fsevent'
  s.add_development_dependency 'rb-fchange'

  # guard notifications
  s.add_development_dependency 'ruby_gntp'

  # fix guard prompt
  s.add_development_dependency 'rb-readline' # or compile ruby w/ readline

  # debuggers
  if /\Aruby/ === RUBY_DESCRIPTION
    s.add_development_dependency 'ruby-debug' if RUBY_VERSION.start_with? '1.8'
    s.add_development_dependency 'debugger'   if RUBY_VERSION.start_with? '1.9'
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
