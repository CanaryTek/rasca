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

  attr_accessor :name, :debug, :verbose, :hostname
  attr_reader :status

  # Possible states
  STATES=["UNKNOWN","OK","CORRECTED","WARNING","CRITICAL"]

  # Initialize the object with the given name. The initial status will be UNKNOWN
  def initialize(name,debug=false,verbose=false,config_dir=nil)
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
end



# Check critical system processes
# Configurable parameters:
# :ps_cmd: ps ax | grep -v grep | grep -q
# Object format
# ---
# process:
#   :regex: regex to find process (OPTIONAL)
#   :ensure: running|stopped
#   :cmd: command to run if ensure is not OK
class CheckProcess < Check
  def initialize(*args)
    super
    # Initialize command to check if a process is running
    @ps_cmd=@config_values.has_key?(:ps_cmd) ? @config_values[:ps_cmd] : "ps ax | grep -v grep | grep -q"
  end
  def check
    # Read Objects
    readObjects(@name)
    
    puts YAML.dump(@objects) if @debug
    @objects.keys.each do |process|
      puts "Checking process: #{process}" if @debug
      @regex=@objects[process].has_key?(:regex) ? @objects[process][:regex] : process
      @ensure=@objects[process].has_key?(:ensure) ? @objects[process][:ensure] : "running"
      if @objects[process].has_key?(:cmd)
        @cmd=@objects[process][:cmd]
      else
        puts "No command for process: #{process}: SKIPPING"
        next
      end
      case @ensure 
        when "running"
          if pidof(@regex)
            # Everything OK
            incstatus("OK")
            puts "OK: #{process} running" if @debug
            @long+="#{process} running. OK\n"
          else
            # 3 tries to start process
            3.times do |try|
              if @debug
                puts "Starting #{process} try #{try}: #{@cmd}"
              else
                @cmd="#{@cmd} >/dev/null 2>&1"
              end
              system(@cmd)
              sleep(1)
              if pidof(@regex)
                incstatus("CORRECTED")
                puts "#{process} started" if @debug
                @short+="#{process} started, "
                @long+="#{process} was not running. STARTED\n"
                break
              else
                if try == 2
                  # CRITICAL if last try
                  incstatus("CRITICAL")
                  @short+="#{process} not started, "
                  @long+="#{process} was not running and COULD NOT BE STARTED\n"
                end
              end
            end
          end
        when "stopped"
          if pidof(@regex)
             3.times do |try|
              if @debug
                puts "Stopping #{process} try #{try}: #{@cmd}"
              else
                @cmd="#{@cmd} >/dev/null 2>&1"
              end
              system(@cmd)
              sleep(1)
              unless pidof(@regex)
                incstatus("CORRECTED")
                puts "#{process} stopped" if @debug
                @short+="#{process} stopped, "
                @long+="#{process} was running. STOPPED\n"
                break
              else
                if try == 2
                  # CRITICAL if last try
                  incstatus("CRITICAL")
                  @short+="#{process} not stopped, "
                  @long+="#{process} was running and COULD NOT BE STOPPED\n"
                end
              end
            end
          else
            # Everything OK
            incstatus("OK")
            puts "OK: #{process} NOT running" if @debug
            @long+="#{process} not running. OK\n"
          end
      end
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="All critical processes running" 
    end
  end
  def pidof(process)
    system(@ps_cmd+" "+process)
  end
end

end # module Rasca
