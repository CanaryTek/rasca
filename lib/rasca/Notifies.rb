module Rasca

require 'digest/md5'

# This package implements notifications using different methods
#
# Nagios: Works as a Nagios plugin
# Print: prints
# nsca: Nagios NSCA alert
# syslog

# Generic notification
# On creation we need to pass these parameters:
#    { :print => nil, :nsca => "nsca_server"}
#
module Notifies
  attr_accessor :long, :short, :print_only
  attr_reader :notifications

  def initialize
    @short=""
    @long=""
  end

  # Initialize notifications array
  def initNotifications(methods)
    # Notifications array
    @notifications=Array.new

      # Initialize notification types
      methods.each do |type,opts|
        case type
          when :print
            puts "Notification: Print" if @debug
            @p=NotifyPrint.new(name,@hostname,opts)
            @p.debug=@debug
            @p.verbose=@verbose
            @notifications.push(@p)
          when :nsca
            puts "Notification: NSCA" if @debug
            @p=NotifyNSCA.new(name,@hostname,opts)
            @p.debug=@debug
            @p.verbose=@verbose
            @notifications.push(@p)
           when :email
            puts "Notification: Email" if @debug
            @p=NotifyEMail.new(name,@hostname,opts)
            @p.debug=@debug
            @p.verbose=@verbose
            @notifications.push(@p)
          else
            raise "Unknown notification method: #{type.to_s}"
        end
      end

    # Send notifications using all methods
    def notify
      # Set short message if empty
      @short="Everything OK" if @short=="" and status=="OK"
      @notifications.each do |method|
        method.notify(@status,@short,@long)
      end
    end

  end

end

# Notify with NSCA
# parameters
class NotifyNSCA
  
  # Mapping between RASCA status and Nagios retcode
  NAGIOS_RETCODE = { "OK" => 0, "CORRECTED" => 0, "WARNING" => 1, "CRITICAL" => 2, "UNKNOWN" => 3}

  attr_accessor :server, :client, :nsca_path, :nsca_conf, :debug, :verbose
  def initialize(name,client,opts)
    @name=name
    @client=client
    @verbose=false
    @debug=false
    # Specific options
    # NSCA host
    if opts.has_key? :server
      @server=opts[:server]
    else
      raise "ERROR: NSCA notification with no server specified"
    end
    # NSCA path
    @nsca_path = opts.has_key?(:nsca_path) ? opts[:nsca_path] : "/usr/sbin/send_nsca"
    @nsca_conf = opts.has_key?(:nsca_conf) ? opts[:nsca_conf] : "/etc/modularit/send_nsca.cfg"
  end
  def notify(status,short,long)
    IO.popen("#{nsca_cmd}>/dev/null",mode="w") do |f|
      f.puts notify_msg(status,short,long)
    end
    puts "cmd: "+nsca_cmd if @debug
    puts "msg: "+notify_msg(status,short,long) if @verbose
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

# Send report by Email
class NotifyEMail
  attr_accessor :name, :client, :debug, :verbose, :address, :mail_cmd
  def initialize(name,client,opts=nil)
    @name=name
    @client=client
    @verbose=false
    @debug=false
    # Initialize default values
    @address = opts.has_key?(:address) ? opts[:address] : "root@localhost"
    @mail_cmd = opts.has_key?(:mail_cmd) ? opts[:mail_cmd] : "/usr/sbin/sendmail -t"
  end
  # Send email
  def notify(status,short,long)
    IO.popen("#{@mail_cmd}",mode="w") do |f|
      f.puts create_mail(status,short,long)
    end
  end
  # Generate the mail message
  def create_mail(status,short,long) 
    message=""
    # Header
    message+="To: #{@address}\n"
    message+="Subject: Rasca alert #{@name} #{status} at #{@client}\n"
    # Separator
    message+="\n"
    # Body
    message+="Host: #{@client}\n"
    message+="Alert #{@name}: #{status}\n"
    message+="---\n"
    message+="#{long}"
    # Return message
    puts message if @debug
    message
  end
end



# Just print message
class NotifyPrint 
  attr_accessor :name, :client, :debug, :verbose
  def initialize(name,client,opts=nil)
    @name=name
    @client=client
    @verbose=false
    @debug=false
  end
  def notify(status,short,long)
    puts @client
    puts @name+": "+status+" "+short
    puts "--"
    puts long
  end
end


end # module Rasca
