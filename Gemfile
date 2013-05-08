source "http://rubygems.org"

gemspec

group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'em-http-request'
  gem 'em-synchrony', :require => false
  gem 'webmock'
  # ensure a reasonable json so multi_json doesn't complain
  gem 'json', '~> 1.7.7'
end

group :development do
  # guard cross-platform listener trick
  gem 'rb-inotify', :require => false
  gem 'rb-fsevent', :require => false
  gem 'rb-fchange', :require => false

  # guard notifications
  gem 'ruby_gntp'

  # fix guard prompt
  gem 'rb-readline' # or compile ruby w/ readline

  # guard
  gem 'guard'
  gem 'guard-rspec'

  # debuggers
  gem 'ruby-debug', :platforms => :mri_18
  gem 'debugger', :platforms => :mri_19
end

