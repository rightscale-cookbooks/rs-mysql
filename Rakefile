require 'mixlib/shellout'
require 'rspec/core/rake_task'
require 'foodcritic'
require 'kitchen'

cookbook=File.foreach('metadata.rb').grep(/^name/).first.strip.split(' ').last.gsub(/'/,'')
directory=File.expand_path(File.dirname(__FILE__))

desc "Sets up knife, and vendors cookbooks"
task :setup_test_environment do
  File.open('knife.rb','w+') do |file|
    file.write <<-EOF
      log_level                :debug
      log_location             STDOUT
      cookbook_path            ['.', 'berks-cookbooks/' ]
    EOF
  end
  system('berks vendor')
end

desc "runs knife cookbook test"
task :knife => [ :setup_test_environment ] do
  cmd = "chef exec bundle exec knife cookbook test #{cookbook} -c knife.rb"
  puts cmd
  knife = Mixlib::ShellOut.new(cmd).run_command
  puts knife.stdout
  puts knife.stderr
end

desc "runs foodcritic"
task :foodcritic do
  cmd = "chef exec bundle exec foodcritic --epic-fail any --tags ~FC009 --tags ~FC064 --tags ~FC065 #{directory}"
  puts cmd
  foodcritic = Mixlib::ShellOut.new(cmd).run_command
  puts foodcritic.stdout
  puts foodcritic.stderr
end

desc "runs rspec"
task :rspec do
  cmd = "bundle exec rspec --color --format documentation"
  puts cmd
  #rspec = Mixlib::ShellOut.new(cmd).run_command
  #puts rspec.stdout
  #puts rspec.stderr
  system(cmd)
end

desc "runs testkitchen"
task :kitchen do
  cmd = "chef exec kitchen test --concurrency=2"
  puts cmd
  kitchen = Mixlib::ShellOut.new(cmd).run_command
  puts kitchen.stdout
  puts kitchen.stderr
end

desc "runs all tests except kitchen"
task :except_kitchen => [ :knife, :foodcritic, :rspec ] do
  puts "running all tests except kitchen"
end

desc "runs all tests"
task :all => [ :except_kitchen, :kitchen ] do
  puts "running all tests"
end
