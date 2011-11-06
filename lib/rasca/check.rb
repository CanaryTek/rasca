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

  attr_accessor :name, :debug, :verbose
  attr_reader :status

  # Possible states
  STATES=["UNKNOWN","OK","CORRECTED","WARNING","CRITICAL"]

  # Initialize the object with the given name. The initial status will be UNKNOWN
  def initialize(name)

    # Initialization of each module (Ruby's super will only call last included Module's constructor)
    UsesObjects.instance_method(:initialize).bind(self).call
    Configurable.instance_method(:initialize).bind(self).call

    # Set name
    @name=name

    # Set initial status
    @status="UNKNOWN"

    # Defaults for debug and verbose
    @verbose=false
    @debug=false

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
      puts "incstatus: #{@status}(#{STATES.index(@status)}) -> #{status}(#{STATES.index(status)})" if @debug
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
  def initialize(name,status)
    super(name)
    @status=status
  end
  # Check just 
  def check
    true
  end
end

end # module Rasca
