module Rasca

# A Simple Template
class CheckPuppet < Check
  def initialize(*args)
    super

    # Initialize config variables
    @wdog_file=@config_values.has_key?(:wdog_file) ? @config_values[:wdog_file] : "/var/lib/puppet/state/watchdog"
    @wdog_age=@config_values.has_key?(:wdog_age) ? @config_values[:wdog_age] : 12*60*60

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
    if File.exists?(@wdog_file)
      puts "watchdog file exists, good!" if @debug
      mtime=File.stat(@wdog_file).mtime
      puts "mtime : "+mtime.to_s if @debug
      if (Time.now - mtime) > @wdog_age
        puts "OLD watchdog file" if @debug
        @short+="OLD watchdog file. Restarting"
        @long+="watchdog file is too old. Puppet may not be working, restarting"
        incstatus("WARNING")
        system("/etc/init.d/puppet restart >/dev/null 2>&1")
      else
        incstatus("OK");
      end
    else
      puts "WARNING: no watchdog file" if @debug
      @short+="NO watchdog file. Restarting"
      @long+="Puppet has no watchdog file, restarting\n"
      incstatus("WARNING")
      system("/etc/init.d/puppet restart >/dev/null 2>&1")
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Puppet watchdog is up to date"
    end
  end
  def info
    %[
== Description

Checks the health of the puppet agent, and restart it if needed
Right now it checks the freshness of a "watchdog" file created by puppet

== Parameters in config file

  :wdog_file: Watchdog file to monitor
  :wdog_age: Max age in seconds. If file is older, restart Puppet

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
