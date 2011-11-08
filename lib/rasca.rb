$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require "rasca/configurable"
require "rasca/usesobjects"
require 'rasca/notifies'
require 'rasca/check'

# Rasca is a modular alert system
module Rasca

  # Rasca version
  VERSION = '0.0.1'

end # module Rasca
