module Rasca

# This class defines a simple Rasca check
class Check < RascaObject

  attr_accessor :proactive, :report_level, :status_change_limit, :status_change_time
  attr_reader :status, :last_status, :status_last_change, :status_change_count

  # Initialize the object with the given name. The initial status will be UNKNOWN
  def initialize(*args)
    super
    # Status flapping detection values
    # A Check is flapping if it changes more than @status_change_limit in a period of @status_change_time seconds
    @status_change_limit=@config_values.has_key?(:status_change_limit) ? @config_values[:status_change_limit] : 5
    @status_change_time=@config_values.has_key?(:status_change_time) ? @config_values[:status_change_time] : 3600
    # Read persistent data
    @classname=self.class.name.sub("Rasca::","")
    @persist=readData(@name,@classname)
    @last_status=@persist.has_key?(:last_status) ? @persist[:last_status] : "OK"
    @status_last_change=@persist.has_key?(:status_last_change) ? @persist[:status_last_change] : 0
    @status_change_count=@persist.has_key?(:status_change_count) ? @persist[:status_change_count] : 0

    # Initialize notificaton object
    if @config_values.has_key? :notify_methods
      @notify_methods=@config_values[:notify_methods]
    else
      @notify_methods={ :print => nil}
    end
      initNotifications(@notify_methods,{:last_status => @last_status, :data_dir => @data_dir})
  end

  # Set the status of he check UNCONDITIONALLY
  def setstatus(status)
    if STATES.include? status
      if is_flapping?
        # If it's flapping, set the highest priority
        if STATES.index(status) > STATES.index(@last_status)
          @status=status
        else
          @status=@last_status
        end
      else
        @status=status
      end
    else
      raise "Unkown status: #{status}"
    end
  end

  # Set status to the given one ONLY IF status is higher criticity than current status
  def incstatus(status)
    if STATES.include? status
      if STATES.index(status) > STATES.index(@status)
        setstatus(status)
      end
    else
      raise "Unkown status: #{status}"
    end
  end

  # Adds message to long report only if status is higher or equal than report_level
  # It's usefull to avoid useless information on reports. We may not want a lot of OK on a report
  def report(status,message)
    if STATES.include? status
      if STATES.index(status) >= STATES.index(@report_level)
        @long+=message
      end
    else
      raise "Unkown status: #{status}"
    end
    # Return long report
    @long
  end

  # Check method. What this check does.
  def check
    puts "You should really redefine the check method"
    incstatus("UNKNOWN")
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
  # Manage flapping detection values on status change
  def update_flapping
    # If @status_change_time has passed after @status_last_change, reset @status_change_count
    if Time.now.to_i >= @status_last_change + @status_change_time
      @status_change_count=0
    end
    # Update status_change_count and status_last_change
    @status_change_count+=1
    @status_last_change=Time.now.to_i
  end
  # Returns true if flapping (more than @status_change_limit status changes in @status_change_time time)
  def is_flapping?
    puts "FLAPPING?: status_change_count >= status_change_limit #{@status_change_count} >= #{@status_change_limit}" if @debug
    @status_change_count >= @status_change_limit
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
