module Rasca

# Check critical package updates
# - Check processes listening to network ports, and check if they need to be updates. 
#   The goal is to make sure that at least all network services are up to date
# - Optionally, can check updates for additional packages
class CheckSecPkg < Check
  attr_accessor :ports_cmd, :openPorts, :check_update_cmd, :packageList, :packagesToUpdate
  def initialize(*args)
    super

    # Instance variables
    # Ports in LISTEN state
    @openPorts=Array.new
    # Packages containing the processes LISTENing on ports
    @packageList=Array.new
    # Packages that needs to be updated
    @packagesToUpdate=Array.new

    # Initialize config variables
    @ports_cmd=@config_values.has_key?(:ports_cmd) ? @config_values[:ports_cmd] : "/usr/sbin/lsof -n -i -P"
    @check_update_cmd=@config_values.has_key?(:check_update_cmd) ? @config_values[:check_update_cmd] : "yum check-update"
    @update_cmd=@config_values.has_key?(:update_cmd) ? @config_values[:update_cmd] : "yum update -y"
    
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

    # Initialize status
    incstatus("OK")

    ## get ports in LISTENing state
    getOpenPorts

    # Report unknown ports
    getUnknownPorts.each do |port|
      incstatus("CRITICAL")
      @short+="Unknown port #{port[:proc]} #{port[:proto]}/#{port[:port]}, "
      @long+="Unknown port #{port[:proc]} #{port[:proto]}/#{port[:port]}\n"
    end

    @packageList=getPackageList

    @packagesToUpdate=getPackagesToUpdate

    if @proactive and not @packagesToUpdate.empty?
	cmd=@update_cmd+" "+@packagesToUpdate.join(" ")
	if @verbose
		puts "Updating packages. Running: "+cmd
	else
		cmd+=">/dev/null 2>&1"
	end
	puts cmd if @debug
	if system(cmd)
            setstatus("CORRECTED")
            @short+="pending packages UPDATED"
            @long+="All pending packages UPDATED\n"
        else
            incstatus("WARNING")
            @short+="could not update packages"
            @long+="Could not update packages\n"
        end
    end

    puts @short if @debug

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="All packages up to date"
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
        entry[:port]=column[column.length-2].split(/:/)[1]
        entry[:proto]=column[column.length-3]
      else
        entry[:port]=column[column.length-1].split(/:/)[1]
        entry[:proto]=column[column.length-2]
      end
      ports.push(entry)
    end
    puts "Open ports: " if @debug
    puts YAML.dump(ports) if @debug
    @openPorts=ports
  end
  # Find out the packages for the listening services
  def getPackageList
    packages=Array.new
    seen_packages=Array.new
    @openPorts.each do |port|
      puts "Checking: "+port[:proc] if @debug
      if @objects.has_key?port[:proc]
        if @objects[port[:proc]].has_key? :package
          package = @objects[port[:proc]][:package]
          unless seen_packages.include? package
            seen_packages.push(package)
            packages.push(package)
	        end
        end
      end
    end
    puts YAML.dump(packages) if @debug
    packages 
  end
  # Find out the packages that needs to be updated
  def getPackagesToUpdate
    packages=Array.new
    @packageList.each do |package|
      # Check if there is an update available
      if system("#{@check_update_cmd} "+package)
            incstatus("OK")
            @long+="Package #{package} up to date\n"
      else
            incstatus("WARNING")
            @short+="#{package} needs to be updated,"
            @long+="Package #{package} needs to be updated\n"
            packages.push(package)
      end
    end
    puts YAML.dump(packages) if @debug
    packages 
  end
 
  # return a list of unknown open ports (not in object files)
  def getUnknownPorts
    ports=Array.new
    @openPorts.each do |entry|
      cmd=entry[:proc]
      port=entry[:port]
      proto=entry[:proto]
       
      if @objects.has_key? cmd
        # Skip of ports contains ANY
        next if @objects[cmd][:ports].member? "ANY"
        # Add port if it is not in process' portlist
        ports.push(entry) unless @objects[cmd][:ports].member? "#{proto}/#{port}"
      else
        ports.push(entry)
      end
    end
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
  :ports_cmd: Command to list open ports and associated commands. Default: "/usr/sbin/lsof -n -i -P"
  :check_update_cmd: Command to check if there are updates for a given package. The package is added after the command.
			Default: "yum check-update"
  :update_cmd: Command to update a package. The package is added after the command. Default: "yum update -y"

== Objects format

  program:   Name of the running program with LISTENing ports
   :package: Package that contains the program (to check for updates). If no package is given, it only checks for open ports, not for updates
   :ports: Array containing ports that can be opened by that program. If it contains ANY, that program can open ANY port

Example:

portmap:
  :package: portmap
  :ports: [ UDP/111, TCP/111 ]
rpc.statd:
  :package: nfs-utils
  :ports: [ ANY ]
zimbra:
  :ports: [ ANY ]
]    
  end
end

end # module Rasca
