$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rasca/Configurable'
require 'rasca/UsesObjects'
require 'rasca/Notifies'
require 'rasca/Check'

# Require all Checks
Dir[File.dirname(__FILE__)+'/rasca/Check?*.rb'].each do |file| 
  require file
end

# Rasca is a modular alert system
module Rasca
  # Rasca version
  VERSION = '0.1.2'
end # module Rasca
