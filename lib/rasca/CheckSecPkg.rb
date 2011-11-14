module Rasca

# Check critical package updates
# - Check processes listening to network ports, and check if they need to be updates. 
#   The goal is to make sure that at least all network services are up to date
# - Optionally, can check updates for additional packages
class CheckSecPkg < Check
  attr_accessor :ports_cmd
  def initialize(*args)
    super

    # Initialize config variables
    @ports_cmd=@config_values.has_key?(:ports_cmd) ? @config_values[:ports_cmd] : "/usr/sbin/lsof -n -i -P"
    
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
    ports=getOpenPorts

    ## Check updates
    ports.each do |port|
      puts "Checking: "+port[:proc] if @debug
      if @objects.has_key?port[:proc]
        
      else
        incstatus("CRITICAL")
        @short+="Unknown port #{port[:proto]}/#{port[:port]}, "
        @long+="Unknown port #{port[:proto]}/#{port[:port]}\n"
      end
      
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end
  # Get the list of open ports
  def getOpenPorts
    puts "Running command: "+@ports_cmd if @debug
    out=`#{@ports_cmd}`.split("\n")
    ports=Array.new
    out.each do |line|
      line.chomp!
      next if line =~ /^COMMAND|->|127.0.0.1:|192.168.122.1:|\[.+\]:/
      puts line if @debug
      entry=Hash.new
      column=line.split(/\s+/)
      entry[:proc]=column[0]
      if column[column.length-1] =~ /LISTEN/
        entry[:port]=column[column.length-2]
        entry[:proto]=column[column.length-3]
      else
        entry[:port]=column[column.length-1]
        entry[:proto]=column[column.length-2]
      end
      ports.push(entry)
    end
    puts "Open ports: " if @debug
    puts YAML.dump(ports) if @debug
    ports
  end
  def info
    %[
== Description

Check critical package updates
- Check processes listening to network ports, and check if they need to be updates. 
  The goal is to make sure that at least all network services are up to date
- Optionally, can check updates for additional packages

== Parameters in config file

  :none: It doesn't use any additional parameter

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
