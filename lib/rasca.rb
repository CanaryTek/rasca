$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# External includes
require 'syslog'
require 'json/pure'

# Rasca
require 'rasca/configurable'
require 'rasca/uses_objects'
require 'rasca/uses_persistent_data'
require 'rasca/notifies'
require 'rasca/object'
require 'rasca/check'
require 'rasca/action'

# Require all Checks
Dir[File.dirname(__FILE__)+'/rasca/check?*.rb'].each do |file| 
  require file
end

# Require all Actions
Dir[File.dirname(__FILE__)+'/rasca/action?*.rb'].each do |file| 
  require file
end

# Require modules
Dir[File.dirname(__FILE__)+'/rasca/*/*.rb'].each do |file| 
  require file
end

# Rasca is a modular alert system
module Rasca
  # Rasca version
  VERSION = '0.1.27'

  # Rasca Check states
  # A Rasca check can be in 5 status:
  # - UNKNOWN: Unknown status. Should be checked ASAP
  # - OK: Everything is OK
  # - CORRECTED: Something was wrong, but it was fixed
  # - WARNING: Something is wrong and should be checked
  # - CRITICAL: Something is not working and should be fixed NOW
  STATES=["UNKNOWN","OK","CORRECTED","WARNING","CRITICAL"]

end # module Rasca
