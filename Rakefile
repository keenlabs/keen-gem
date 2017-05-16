require 'bundler'
require 'rspec/core/rake_task'

desc "Run Rspec unit tests"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/keen/**/*_spec.rb"
end

desc "Run Rspec integration tests"
RSpec::Core::RakeTask.new(:integration) do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
end

desc "Run Rspec synchrony tests"
RSpec::Core::RakeTask.new(:synchrony) do |t|
  t.pattern = "spec/synchrony/**/*_spec.rb"
end

desc "Run Rspec pattern"
RSpec::Core::RakeTask.new(:pattern) do |t|
  t.pattern = "spec/#{ENV['PATTERN']}/**/*_spec.rb"
end

desc "Start a development console with local code loaded"
task :console do
  exec "irb -r keen -I ./lib"
end

task :default => :spec
task :test => [:spec]
