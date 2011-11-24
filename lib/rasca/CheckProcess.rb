module Rasca
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
    
    @objects.keys.each do |process|
      puts "Checking process: #{process}" if @debug
      @regex=@objects[process].has_key?(:regex) ? @objects[process][:regex] : process
      @ensure=@objects[process].has_key?(:ensure) ? @objects[process][:ensure] : "running"
      if @objects[process].has_key?(:cmd)
        @cmd=@objects[process][:cmd]
      else
        puts "No command for process: #{process}: SKIPPING" if @debug
        next
      end
      puts "#{process} should be #{@ensure}" if @debug
      case @ensure 
        when "started"
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
  def info
    %[
== Description

Checks that configured critical process are started or stopped, and tries to fix any problems it founds

== Parameters in config file

  :ps_cmd: Command to check if a process is running. Adds the process name to the end.
            Default: "ps ax | grep -v grep | grep -v "+ procname

== Objects format

Objects dir: #{@object_dir}/#{@name}

  process_name:
    :regex: You can define a grep regex instead of looking for the process name OPTIONAL
    :ensure: started|stopped Defines if the service should
            Default: started
    :cmd: Command to run if process is not in the expected status 

  Example:
sshd:
  :ensure:  started
  :cmd: service sshd restart
vsftpd:
  :ensure: stopped
  :cmd: service vsftpd stop
]
  end

end

end # module Rasca
