
require 'rubygems'
require './lib/rasca'

Gem::Specification.new do |s|
  s.name = %q{rasca}
  s.version = Rasca::VERSION
  s.date = %q{2007-09-03}
  s.authors = ["Miguel Armas"]
  s.email = %q{kuko@canarytek.com}
  s.summary = %q{RASCA Alert framework}
  s.homepage = %q{http://www.modularit.org/}
  s.description = %q{RASCA Alert framework for ModularIT}
  s.files = Dir[ "README.txt", "History.txt", "bin/rasca*", "lib/rasca.rb","lib/rasca/*.rb","lib/rasca/*/*.rb"]
  s.bindir = 'bin'
  s.executables = ['rascaCheck','rascaAction','rascaBackup']
end
