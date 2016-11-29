source 'https://rubygems.org'

gem 'berkshelf', '~> 4'
gem 'faraday', '= 0.9.1'
gem 'varia_model', '~> 0.4.1'
gem 'thor-foodcritic'
gem 'rake'
gem 'chef', '~> 11'

group :integration do
  # Prior to 0.1.6, libyaml is vulnerable to a heap overflow exploit from malicious YAML payloads.
  # This solution is suggested to update psych:
  # https://www.ruby-lang.org/en/news/2014/03/29/heap-overflow-in-yaml-uri-escape-parsing-cve-2014-2525/
  gem 'psych', '~> 2.0.5'
  gem 'test-kitchen', '~> 1.2.1'
  gem 'kitchen-vagrant'
  gem 'chefspec', '~> 3.4.0'
  gem 'travis-lint'
  gem 'mysql'
  gem 'rspec-expectations', '~> 2.14.0'
  gem 'rack', '= 1.6.4'
  gem 'json', '~> 1.8', '>= 1.8.3'
  gem 'buff-ignore', '= 1.1.1'
  gem 'net-http-persistent', '= 2.9.4'
end
