source 'https://rubygems.org'

gem 'berkshelf','~> 5.0'
gem 'thor-foodcritic'

group :integration do
  # Prior to 0.1.6, libyaml is vulnerable to a heap overflow exploit from malicious YAML payloads.
  # This solution is suggested to update psych:
  # https://www.ruby-lang.org/en/news/2014/03/29/heap-overflow-in-yaml-uri-escape-parsing-cve-2014-2525/
  gem 'psych'
  gem 'test-kitchen'
  gem 'kitchen-vagrant'
  gem 'chefspec', '~> 5.0'
  gem 'travis-lint'
  gem 'mysql2'
  gem "machine_tag"
end
