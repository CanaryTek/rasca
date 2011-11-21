# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/rasca'

Hoe.spec 'rasca' do
  developer('Miguel Armas', 'kuko@canarytek.com')

  # self.rubyforge_name = 'rascax' # if different than 'rasca'
end

task :publish do
    sh "scp pkg/rasca-#{Rasca::VERSION}.gem root@gems.canarytek.com:/var/www/gems-repo/gems"
    sh "ssh root@gems.canarytek.com \"gem generate_index -d /var/www/gems-repo\""
end

# vim: syntax=ruby
