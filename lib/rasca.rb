$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# External includes
require 'syslog'

# Rasca
require 'rasca/Configurable'
require 'rasca/UsesObjects'
require 'rasca/UsesPersistentData'
require 'rasca/Notifies'
require 'rasca/RascaObject'
require 'rasca/Check'
require 'rasca/Action'

# Require all Checks
Dir[File.dirname(__FILE__)+'/rasca/Check?*.rb'].each do |file| 
  require file
end

# Require all Actions
Dir[File.dirname(__FILE__)+'/rasca/Action?*.rb'].each do |file| 
  require file
end

# Require modules
Dir[File.dirname(__FILE__)+'/rasca/*/*.rb'].each do |file| 
  require file
end

# Rasca is a modular alert system
module Rasca
  # Rasca version
  VERSION = '0.1.8'

  # Rasca Check states
  # A Rasca check can be in 5 status:
  # - UNKNOWN: Unknown status. Should be checked ASAP
  # - OK: Everything is OK
  # - CORRECTED: Something was wrong, but it was fixed
  # - WARNING: Something is wrong and should be checked
  # - CRITICAL: Something is not working and should be fixed NOW
  STATES=["UNKNOWN","OK","CORRECTED","WARNING","CRITICAL"]

end # module Rasca
