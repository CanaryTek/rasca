module Rasca

# This package implements notifications using different methods
#
# Nagios: Works as a Nagios plugin
# Print: prints
# nsca: Nagios NSCA alert
# syslog

# Generic notification class
# On creation we need to pass these parameters:
# name: The name of the Notification (Alert)
# client: The client machine that is originating this alert
# methods: a Hash of methods and destinations
#    The destination depends on the notification type:
#    { :print => nil, :nsca => "nsca_server"}
#
class Notification
  attr_accessor :long, :short, :name, :client
  attr_reader :notifications

  # 
  def initialize(name,client,methods)
    # Short message (1 line)
    @short = ""
    # Long message (multiline)
    @long = ""
    # Notifications array
    @notifications=Array.new

    # Initialize notification types
    methods.each do |type,dest|
      puts "#{type.to_s} -> #{dest}"
      case type
        when :print
          @notifications.push(NotifyPrint.new(name,client))
        when :nsca
          @notifications.push(NotifyNSCA.new(name,client,dest))
        else
          raise "Unknown notyfication method: #{type.to_s}"
      end
    end

    # Send notifications using all methods
    def notify
      @notifications.each do |method|
        method.notify(@short,@long)
      end
    end

  end

end

# Notify with NSCA
# parameters
class NotifyNSCA
  
  # Mapping between RASCA status and Nagios retcode
  NAGIOS_RETCODE = { "OK" => 0, "CORRECTED" => 0, "WARNING" => 1, "CRITICAL" => 2, "UNKNOWN" => 3}

  attr_accessor :server, :client, :nsca_path, :nsca_conf
  def initialize(name,client,server,nsca_path="/usr/bin/send_nsca",nsca_conf="/etc/modularit/send_nsca.cfg")
    @name=name
    @client=client
    @server=server
    @nsca_path=nsca_path
    @nsca_conf=nsca_conf
  end
  def notify(status,short,long)
    # FIXME: Convert status to nagios RETCODE
    retcode=1
    puts "cmd: #{@nsca_cmd} -H #{@server} -c #{@nsca_conf}"
    puts "msg: #{@client}\t#{@name}\t#{retcode}\t#{short}"
  end
  def nsca_cmd
    "#{@nsca_path} -H #{@server} -c #{@nsca_conf}"
  end
  def retcode(status)
    NAGIOS_RETCODE[status] 
  end
  def notify_msg(status,short,long)
    "#{@client}\t#{@name}\t#{retcode(status)}\t#{short}"
  end
end

# Just print message
class NotifyPrint 
  attr_accessor :name, :client
  def initialize(name,client)
    @name=name
    @client=client
  end
  def notify(status,short,long)
    puts @client
    puts @name+": "+status+" "+short
    puts "--"
    puts long
  end
end


end # module Rasca
