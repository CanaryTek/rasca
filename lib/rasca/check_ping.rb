module Rasca
# Check connectivity using ping
class CheckPing < Check
  def initialize(*args)
    super
  end
  def check
    # Read Objects
    readObjects(@name)
    # If nothing to check, status should be OK
    incstatus("OK")
    
    @objects.keys.each do |node|
      puts "Checking node: #{node}" if @debug
      # Set defaults
      @source=nil
      @cmd=nil
      @desc=""
      @ping_cmd="ping"
      @forced_status="CRITICAL"
      if @objects[node].is_a?Hash
        # Override with object parameters
        @ip=@objects[node].has_key?(:ip) ? @objects[node][:ip] : node
        @forced_status=@objects[node][:status] if @objects[node].has_key?(:status)
        @source=@objects[node][:source] if @objects[node].has_key?(:source)
        @cmd=@objects[node][:cmd] if @objects[node].has_key?(:cmd)
        @desc=@objects[node][:desc] if @objects[node].has_key?(:desc)
        @ping_cmd=@objects[node][:ping_cmd] if @objects[node].has_key?(:ping_cmd)
      else
        @ip=node
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
            incstatus("WARNING")
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


== Objects format

Objects dir: #{@object_dir}/#{@name}

  node:
    :ip: node IP address. If not given, we use the node name
    :status: status to set if node is not available
    :source: source IP to use
    :cmd: command to run if connectivity lost
    :desc: Description to add in alert
    :ping_cmd: Ping command. Default: "ping"

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
