module Rasca
# Check connectivity using ping
class CheckPing < Check
  def initialize(*args)
    super
    # Initialize command to check if a process is running
    @ping_cmd=@config_values.has_key?(:ping_cmd) ? @config_values[:ping_cmd] : "/usr/bin/ping"
  end
  def check
    # Read Objects
    readObjects(@name)
    
    @objects.keys.each do |node|
      puts "Checking node: #{node}" if @debug
      if @objects[node].is_a?Hash
        @ip=@objects[node].has_key?(:ip) ? @objects[node][:ip] : node
        @forced_status=@objects[node].has_key?(:status) ? @objects[node][:status] : "CRITICAL"
        @source=@objects[node][:source] if @objects[node].has_key?(:source)
        @cmd=@objects[node][:cmd] if @objects[node].has_key?(:cmd)
        @desc=@objects[node][:desc] if @objects[node].has_key?(:desc)
      else
        @ip=node
        @forced_status="CRITICAL"
      end
      if ping(@ip,@source)
        # Everything OK
        incstatus("OK")
        puts "OK: #{node} available" if @debug
        @long+="#{node} available. OK\n"
      else
        # 3 tries
        3.times do |try|
          if @debug
            puts "Recovering #{node} try #{try}: #{@cmd}"
          else
            @cmd="#{@cmd} >/dev/null 2>&1"
          end
          system(@cmd) if (@cmd)
          sleep(3)
          if ping(@ip,@source)
            incstatus(@forced_status)
            puts "#{node} recovered" if @debug
            @short+="#{node} recovered, "
            @long+="#{node} was not available but was recovered\n"
            break
          else
            if try == 2
              # CRITICAL if last try
              incstatus(@forced_status)
              @short+="#{node} not available, "
              @long+="#{node} was not available, and could NOT be recovered\n"
            end
          end
        end
      end
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="All critical nodes available" 
    end
  end
  def ping(ip,source)
    source = "-I #{source}" if source 
    out = ">/dev/null 2>&1" unless @debug
    cmd="#{@ping_cmd} -c 5 -q #{source.to_s} #{ip} #{out.to_s}"
    puts "running: #{cmd}" if @debug
    system(cmd)
  end
  def info
    %[
== Description

Checks connectivity to critical IP. If ping fails, it can run a command to restore connectivity

== Parameters in config file

  :ping_cmd: Ping command. Default: "/usr/bin/ping"

== Objects format

Objects dir: #{@object_dir}/#{@name}

  node:
    :ip: node IP address. If not given, we use the node name
    :status: status to set if node is not available
    :source: source IP to use
    :cmd: command to run if connectivit lost
    :desc: Description to add in alert

  Example:
node1:
ipsec_node:
  :ip:  10.1.1.101
  :source: 10.1.1.111
  :cmd: ipsec auto --up tunnel1
  :desc: IPSec tunnel 1
remote_node:
  :desc: Critical remote node
]
  end

end

end # module Rasca
