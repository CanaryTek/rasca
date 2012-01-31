module Rasca

# A Simple Template
class CheckTripwire < Check
  def initialize(*args)
    super

    ## Initialize config variables
    # Directory where we will write te TripWire reports
    @tw_report_dir=@config_values.has_key?(:tw_report_dir) ? @config_values[:tw_report_dir] : "/var/lib/tripwire/report"
    # Tripwire check command
    @tw_check_cmd=@config_values.has_key?(:tw_check_cmd) ? @config_values[:tw_check_cmd] : "/usr/sbin/tripwire --check"
    # Tripwire update command
    @tw_update_cmd=@config_values.has_key?(:tw_update_cmd) ? @config_values[:tw_update_cmd] : "/usr/sbin/tripwire --update"

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
    output=`#{@tw_check_cmd} 2>/dev/null`	
    retcode=$?.exitstatus
    changes=false
    case retcode
      when 0
        # Everything OK
        incstatus("OK")
        @short = "No changes in filesystem"
      when 8
        # Something found
        incstatus("UNKNOWN")
        @short = "ERROR: Unknown error runnig Tripwire, is it installed?"
        @long = output
      else
        incstatus('WARNING')
        @short = "Changes in the Filesystem."
        @long = output
	changes=true
    end


    if @proactive and changes
      # Last report File
      report=Dir["#{@tw_report_dir}/*.twr"].sort.last

      puts "Updating tripwire DB. Report: #{report}" if @debug
      cmd="#{@tw_update_cmd} -r #{report}"
      puts "Running: #{cmd}" if @debug
      system(cmd)
      setstatus('CORRECTED')
      @short+=" UPDATED CHANGES"

    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end
  def cleanup
    keep=20
    files=Dir["#{@tw_report_dir}/*"].sort
    if files.length > keep
      to_delete=files.slice(0,files.length-keep)
      puts "Deleting: "+to_delete.join(" ") if @debug
      FileUtils.rm to_delete
    end
  end
  def info
    %[
== Description

Uses Tripwire to do a filesystem integrity check

== Parameters in config file

  :tw_report_dir: Directory where tripwire creates the reports. Default: "/var/lib/tripwire/report"
  :tw_check_cmd: Tripwire check command. Default: "/usr/sbin/tripwire --check"
  :tw_update_cmd: Tripwire update command. Default: "/usr/sbin/tripwire --update"

== Objects format

  none:
]    
  end
end

end # module Rasca
