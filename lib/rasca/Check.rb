module Rasca

# This class defines a simple Rasca check
# A Rasca check can be in 5 status:
# - UNKNOWN: Unknown status. Should be checked ASAP
# - OK: Everything is OK
# - CORRECTED: Something was wrong, but it was fixed
# - WARNING: Something is wrong and should be checked
# - CRITICAL: Something is not working and should be fixed NOW
class Check
  include Configurable
  include UsesObjects
  include Notifies

  attr_accessor :name, :debug, :verbose, :hostname, :testing
  attr_reader :status

  # Possible states
  STATES=["UNKNOWN","OK","CORRECTED","WARNING","CRITICAL"]

  # Initialize the object with the given name. The initial status will be UNKNOWN
  def initialize(name,debug=false,verbose=false,config_dir=nil)
    # testing=true is used for unit testing.
    # normal whe use it to use test input instead of the real system command
    @testing=false

    # Set name. This needs to be first
    @name=name
    # Set initial status
    @status="UNKNOWN"
    # Defaults for debug and verbose
    @debug=debug
    @verbose=verbose
    @verbose=true if @debug
    # Print_only
    @print_only=false

    # Config_values
    @config_values=Hash.new

    # Initialization of each module (Ruby's super will only call last included Module's constructor)
    Configurable.instance_method(:initialize).bind(self).call(config_dir)
    Notifies.instance_method(:initialize).bind(self).call

    # Set client hostname
    puts YAML.dump(@config_values) if @debug
    @hostname=@config_values[:hostname]

    # Initializes UsesObjects
    @object_dir=@config_values.has_key?(:object_dir) ? @config_values[:object_dir] : DEFAULT_OBJECTS_DIR
    UsesObjects.instance_method(:initialize).bind(self).call(@object_dir)

    # Initialize notificaton object
    if @config_values.has_key? :notify_methods
      @notify_methods=@config_values[:notify_methods]
    else
      @notify_methods={ :print => nil}
    end
    initNotifications(@notify_methods)

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

  # Cleanup. Clean up if needed
  def cleanup
    true
  end

  # Info. Print information about the check
  # - What it does
  # - The object format
  # - Optionaly what to do to correct problems
  def info
    %[
== Description

IF YOU SEE THIS IN A REAL CHECK, YOU NEED TO REDEFINE info() METHOD

This check does nothing. It's used as a base class for "real" checks

== Parameters in config file

  :none: It doesn't use any additional parameter

== Objects format

  :none:
    :option1: 
]
  end
end

# This class is a fake Check that always returns the status given in the initialization
class CheckFake < Check
  def initialize(name,status)
    super(name)
    @status=status
    @short="#{name} #{status}"
  end
end

# Simple check that sends an OK (basically to detect down hosts that use NSCA)
class CheckPingHost < Check
  def initialize(*args)
    super
    @status="OK"
    @short="#{name} OK"
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
