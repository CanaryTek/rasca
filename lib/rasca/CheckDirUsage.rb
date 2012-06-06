module Rasca

#
# Checks size of directories
#
class CheckDirUsage < Check
  def initialize(*args)
    super
    # Command to get dir usage. Default: "du -sh "
    @du_cmd=@config_values.has_key?(:du_cmd) ? @config_values[:du_cmd] : "du -sh 2>/dev/null"
    @default_warning_limit=@config_values.has_key?(:warning_limit) ? @config_values[:warning_limit] : "1G"
    @default_critical_limit=@config_values.has_key?(:critical_limit) ? @config_values[:critical_limit] : "1G"
  end
  def check
    # Read Objects
    readObjects(@name)
    
    # Get filesystem usage
    objects.keys.each do |entry|

      # Expand if its a file glob
      Dir[entry].each do |dir|

        # Skip entry if its a fileglob expansion a we have a more specific entry
        if entry != dir and objects.has_key? dir
          puts "Skipping #{dir} because defined elsewhere" if @debug
        else
          puts "Checking usage of #{dir}" if @debug
          @warning_limit=@objects[entry].has_key?(:warning_limit) ? @objects[entry][:warning_limit] : @default_warning_limit
          @critical_limit=@objects[entry].has_key?(:critical_limit) ? @objects[entry][:critical_limit] : @default_critical_limit
          @usage=du_h(dir)
          puts "Testing #{dir}: #{@usage} limits: warning=#{@warning_limit} critical=#{@critical_limit}" if @debug
          # See if we have limits for this filesystem
          # Check usage against limits
          if usage_bigger(@usage,@critical_limit)
            # if warning_limit==critical_limit we keep it in warning
            if @warning_limit == @critical_limit
              incstatus("WARNING")
              report("WARNING","Usage of #{dir} is #{@usage} WARNING\n")
            else
              incstatus("CRITICAL")
              report("CRITICAL","Usage of #{dir} is #{@usage} CRITICAL\n")
            end
            @short+="#{dir} -> #{@usage}, "
          elsif usage_bigger(@usage,@warning_limit)
            incstatus("WARNING")
            @short+="#{dir} -> #{@usage}, "
            report("WARNING","Usage of #{dir} is #{@usage} WARNING\n")
          else
            incstatus("OK")
            report("OK","Usage of #{dir} is #{@usage} OK\n")
          end
        end
      end

   end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="All directory usage OK" 
    end
  end

  # Return true if usage is bigger than limit
  # We need this because usage and limits are reported with letter (G: Giga,M: Mega,K: Kilo)
  def usage_bigger(usage,limit)
    # Force parameters to string
    usage=usage.to_s
    limit=limit.to_s
    # Convert usage
    if usage.end_with? "G"
      usage=usage.chop.to_f*1024*1024*1024
    elsif usage.end_with? "M"
      usage=usage.chop.to_f*1024*1024
    elsif usage.end_with? "K"
      usage=usage.chop.to_f*1024
    else
      usage=usage.to_f
    end
    # Convert limit
    if limit.end_with? "G"
      limit=limit.chop.to_f*1024*1024*1024
    elsif limit.end_with? "M"
      limit=limit.chop.to_f*1024*1024
    elsif limit.end_with? "K"
      limit=limit.chop.to_f*1024
    else
      limit=limit.to_f
    end
    # Compare
    usage >= limit
  end

  # Return an array with entries based on output from "df -h" or similar command
  def du_h(dir)
    puts "Running command: #{@du_cmd} #{dir}" if @debug
    usage=`#{@du_cmd} #{dir}`.split.first
    puts "Usage of #{dir}: #{usage}" if @debug
    usage
  end
  def info
    %[
== Description

Checks directory usage to detect directories that are over a given size limit

== Parameters in config file

  :du_cmd: Command to get directory usage. Default: "du -h"
  :default_warning_limit: Default warning limit. Default: 90
  :default_critical_limit: Default critical limit. Default 100

== Objects format

Objects dir: #{@object_dir}/#{@name}

  directory:
    :warning_limit: usage over this percentage is WARNING
    :critical_limit: usage over this percentage is CRITICAL
    :action: command to run if usage is over threshold. OPTIONAL 

  Example:

/home/profiles:
  :critical_limit: 60
  :warning_limit: 50
/:
  :critical_limit: 50
  :warning_limit: 100

]    
  end
end


end # module Rasca
