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

  # Close. Some housekeeping, should be really a destructor
  def close
    puts "status: #{@status} last_status: #{@last_status}" if @debug
    update_flapping() if @status != @last_status
    @persist[:last_status]=@status
    @persist[:status_last_change]=@status_last_change
    @persist[:status_change_count]=@status_change_count
    writeData(@name,@classname)
  end

  # Run method. What this action does.
  def run
    puts "You should really redefine the run method"
  end
end

end # module Rasca
