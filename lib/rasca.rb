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

  # Default config dir
  DEFAULT_CONFIG_DIR = "/etc/modularit"

  # Default objects dir FIXME: This should be really in the config file
  DEFAULT_OBJECTS_DIR = "/var/lib/modularit/obj"

end # module Rasca
