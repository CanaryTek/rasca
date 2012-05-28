module Rasca

# This class defines a simple Rasca check
# A Rasca check can be in 5 status:
# - UNKNOWN: Unknown status. Should be checked ASAP
# - OK: Everything is OK
# - CORRECTED: Something was wrong, but it was fixed
# - WARNING: Something is wrong and should be checked
# - CRITICAL: Something is not working and should be fixed NOW
class Check < RascaObject

  attr_accessor :proactive
  attr_reader :status

  # Possible states
  STATES=["UNKNOWN","OK","CORRECTED","WARNING","CRITICAL"]

  # Initialize the object with the given name. The initial status will be UNKNOWN
  def initialize(*args)
    super
  end

  # Set the status of he check UNCONDITIONALLY
  def setstatus(status)
    if STATES.include? status
      @status=status
    else
      raise "Unkown status: #{status}"
    end
  end

  # Set status to the given one ONLY IF status is higher criticity than current status
  def incstatus(status)
    if STATES.include? status
      if STATES.index(status) > STATES.index(@status)
        @status=status
      end
    else
      raise "Unkown status: #{status}"
    end
  end

  # Check method. What this check does.
  def check
    puts "You should really redefine the check method"
    incstatus("UNKNOWN")
  end
end

# This class is a fake Check that always returns the status given in the initialization
class CheckFake < Check
  def initialize(name,status,config_dir=nil,debug=false,verbose=false,read_objects=true)
    super(name,config_dir,debug,verbose,read_objects)
    @status=status
    @short="#{name} #{status}"
  end
  def check
    true
  end
end

# Simple check that sends an OK (basically to detect down hosts that use NSCA)
class CheckPingHost < Check
  def initialize(*args)
    super
    @status="OK"
    @short="#{name} OK"
  end
  def check
    true
  end
  def info
    %[
== Description

This check just notifies an OK.
It's used as a Host's heartbeat to detect failed servers in asynchoronous alerts (NSCA)

== Parameters in config file

None.

== Objects format

Doesn't use objects

]    
  end
end

end # module Rasca
