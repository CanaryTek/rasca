module Rasca

#
# Simple check that sends an OK (basically to detect down hosts that use NSCA)
class CheckFSUsage < Check
  def initialize(*args)
    super
    # Command to get filesystem usage. Default: "df -h | grep -v ^Filesystem"
    @df_cmd=@config_values.has_key?(:df_cmd) ? @config_values[:df_cmd] : "df -h | grep -v ^Filesystem"
    @exclude_regex=@config_values.has_key?(:exclude_regex) ? @config_values[:exclude_regex] : %r[^tmpfs$|^udev$|^rootfs$]
    @default_warning_limit=@config_values.has_key?(:warning_limit) ? @config_values[:warning_limit] : 90
    @default_critical_limit=@config_values.has_key?(:critical_limit) ? @config_values[:critical_limit] : 100
  end
  def check
    # Read Objects
    readObjects(@name)
    
    # Get filesystem usage
    df_h.each do |entry|
      next if entry[:device] =~ @exclude_regex

      # See if we have limits for this filesystem
      @mountpoint=entry[:mountpoint]
      @usage=entry[:pctused]
      if @objects.has_key?(@mountpoint)
        @warning_limit=@objects[@mountpoint].has_key?(:warning_limit) ? @objects[@mountpoint][:warning_limit] : @default_warning_limit
        @critical_limit=@objects[@mountpoint].has_key?(:critical_limit) ? @objects[@mountpoint][:critical_limit] : @default_critical_limit
      else
        # No specific limits, use defaults
        @warning_limit=@default_warning_limit
        @critical_limit=@default_critical_limit
      end
      puts "Testing #{@mountpoint}: #{@usage} limits: warning=#{@warning_limit} critical=#{@critical_limit}" if @debug
      # Check usage against limits
      if @usage.to_i > @critical_limit
        # if warning_limit==100 we keep it in warning. So we can skip criticals from filesystems we don't care
        if @warning_limit == 100
          incstatus("WARNING")
        else
          incstatus("CRITICAL")
        end
        @short+="#{@mountpoint} -> #{@usage}, "
        @long+="Usage of #{@mountpoint} is #{@usage} CRITICAL\n"
      elsif @usage.to_i > @warning_limit
        incstatus("WARNING")
        @short+="#{@mountpoint} -> #{@usage}, "
        @long+="Usage of #{@mountpoint} is #{@usage} WARNING\n"
      else
        incstatus("OK")
        @long+="Usage of #{@mountpoint} is #{@usage} OK\n"
      end
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="All filesystems OK" 
    end
  end

  # Return an array with entries based on output from "df -h" or similar command
  def df_h
    puts "Running command: "+@df_cmd if @debug
    @out=`#{@df_cmd}`.split
    @df=Array.new
    while @out.length > 0
      @line=@out.slice!(0,6)
      @entry=Hash.new
      @entry[:device]=@line[0]
      @entry[:size]=@line[1]
      @entry[:used]=@line[2]
      @entry[:avail]=@line[3]
      @entry[:pctused]=@line[4].chop
      @entry[:mountpoint]=@line[5]
      @df.push(@entry)
    end 
    puts "Filesystems: " if @debug
    puts YAML.dump(@df) if @debug
    @df
  end
  def info
    %[
== Description

Checks filesystem usage to detect filesystems that are almost full

== Parameters in config file

  :df_cmd: Command to get filesystem usage. Default: "df -h | grep -v ^Filesystem"
  :exclude_regex: Regex of devices to exclude. Default: %r[^tmpfs$|^udev$|^rootfs$]
  :default_warning_limit: Default warning limit. Default: 90
  :default_critical_limit: Default critical limit. Default 100

== Objects format

Objects dir: #{@object_dir}/#{@name}

  mountpoint:
    :warning_limit: usage over this percentage is WARNING
    :critical_limit: usage over this percentage is CRITICAL
    :action: command to run if usage is over threshold. OPTIONAL 

  Example:

/var:
  :critical_limit: 60
  :warning_limit: 50
/:
  :critical_limit: 50
  :warning_limit: 100

]    
  end
end


end # module Rasca
