# -*- ruby -*-

require 'rake/testtask'
require 'rubygems'
require './lib/rasca'

task :gem do
  sh "gem build rasca.gemspec; mv rasca-#{Rasca::VERSION}.gem pkg/"
end

task :publish do
    sh "scp pkg/rasca-#{Rasca::VERSION}.gem root@gems.canarytek.com:/var/www/gems-repo/gems"
    sh "ssh root@gems.canarytek.com \"gem generate_index -d /var/www/gems-repo\""
end

task :test do
  Rake::TestTask.new do |t|
    t.libs << "test"
    t.test_files = FileList['test/test_*.rb']
    t.verbose = true
  end
end

# vim: syntax=ruby
