module Rasca

# A Simple Template
class CheckTemplate < Check
  def initialize(*args)
    super

    # Initialize config variables
    @variable1=@config_values.has_key?(:variable1) ? @config_values[:variable1] : "Default for variable1"

    # More initialization
    #
  end
  # The REAL Check
  def check
    @objects=readObjects(@name)
    
    if @testing
      # Use testing input (for unit testing)
    else
      # Use REAL input
    end

    ## CHECK CODE 

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end
  def info
    %[
== Description

This is just a template

== Parameters in config file

  :none: It doesn't use any additional parameter

== Objects format

  none:
    :option1: 

Example:

none:
  :option: Option1

]    
  end
end

end # module Rasca
