module Rasca

# This class defines a simple Rasca action
class Action < RascaObject

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

  # Run method. What this action does.
  def run
    puts "You should really redefine the run method"
  end
end

end # module Rasca
