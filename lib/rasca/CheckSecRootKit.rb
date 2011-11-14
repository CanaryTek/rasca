module Rasca

# A Simple Template
class CheckSecRootKit < Check
  def initialize(*args)
    super

    # Initialize config variables
    @rkhunter_cmd=@config_values.has_key?(:rkhunter_cmd) ? @config_values[:rkhunter_cmd] : "/usr/bin/rkhunter --cronjob --rwo --disable promisc --enable suspscan"

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
    retcode=system(@rkhunter_cmd)

    case retcode 
      when 0
        # Everything OK
        inctstatus("OK")
        @short = "No RootKits detected"
      when 1
        # Something found
        incstatus("WARNING")
        @short="Suspicious activity. Check /var/log/rkhunter/rkhunter.log"
      else
        incstatus('CRITICAL')
        @short = "UNKNOWN ERROR"
    end
    # FIXME: Add report to @long?

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end
  def info
    %[
== Description

Checks for traces of insalled rootkits or intrusions.

Uses the program rkhunter

== Parameters in config file

  :rkuhnter_cmd: Command to run rkhunter
                  Default: "/usr/bin/rkhunter --cronjob --rwo --disable promisc --enable suspscan"

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
