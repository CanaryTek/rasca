module Rasca

# Check RAID devices
class CheckRAID < Check
  def initialize(*args)
    super
    
  end
  def check
    @objects=readObjects(@name)

    # Check MD devices
    check_md
  end
  # Check Linux Software Raid (MD)
  def check_md
    # mdstatus file
    if @testing
      @mdstat_file=@testing
    else
      @mdstat_file="/proc/mdstat"
    end
    puts "Using mdstat file from: "+@mdstat_file.to_s if @debug
    # Flag to see if we found md arrays
    @arraysdefined=false    
    @device=nil

    File.open(@mdstat_file).each do |line|
      if line =~ /^(md[0123456789]+)/
        @arraysdefined=true
        @device=$1
        puts "Found device: #{@device}" if @debug
      end
      if (@device)
        # Default status of not broken
        incstatus("OK")
        puts "IN device: "+@device if @debug
        if @objects.has_key?(@device)
          newstatus=@objects[@device].has_key?(:status) ? @objects[@device][:status] : "CRITICAL"
        else
          newstatus="CRITICAL"
        end
        if line =~ /\[U_\]/ or line =~ /\[_U\]/
          puts "|#{@device}| broken: "+line if @debug
          incstatus(newstatus)
          @short+="#{@device} broken, "
          @long+="Device #{@device} is BROKEN. #{newstatus}"
        end
        if line =~ /^\s*$/
          puts "END device : #{@device}" if @debug
          @device = false
          incstatus("OK")
        end
      end
    end
    unless @arraysdefined
      puts "No arrays defined" if @debug
      incstatus("OK")
      @short = "No arrays defined"
    end
  end
  def info
    %[
== Description

Checks status of RAID arrays. It checks the following RAID devices:
 - Linux software RAID (/dev/mdstat)

== Parameters in config file

None.

== Objects format

Objects dir: #{@object_dir}/#{@name}

  device:
    :status: Status if array broken. Default: CRITICAL

Example:

md0:
  :status: WARNING

]    
  end
end

end # module Rasca
