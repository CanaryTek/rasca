module Rasca

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
  def initNotifications(methods,params={})
    # Notifications array
    @notifications=Array.new
    
      # Initialize notification types
      methods.each do |type,opts|
        case type
          when :print
            puts "Notification: Print" if @debug
            @p=NotifyPrint.new(name,@hostname,opts,params)
            @p.debug=@debug
            @p.verbose=@verbose
            @notifications.push(@p)
          when :nsca
            puts "Notification: NSCA" if @debug
            @p=NotifyNSCA.new(name,@hostname,opts,params)
            @p.debug=@debug
            @p.verbose=@verbose
            @notifications.push(@p)
          when :email
            puts "Notification: Email" if @debug
            @p=NotifyEMail.new(name,@hostname,opts,params)
            @p.debug=@debug
            @p.verbose=@verbose
            @notifications.push(@p)
          when :syslog
            puts "Notification: Syslog" if @debug
            @p=NotifySyslog.new(name,@hostname,opts,params)
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

# Generic Notification (superclass)
class Notify
  attr_accessor :name, :client, :debug, :verbose

  # Uses persistent data to store last notification timestamp
  # The YAML file will be named after the class name
  include UsesPersistentData

  def initialize(name,client,opts={},params={})
    @name=name
    @client=client
    if opts.is_a? Hash
      @opts=opts
    else
      @opts=Hash.new
    end
    if params.is_a? Hash
      @params=params
    else
      @params=Hash.new
    end
    @verbose=false
    @debug=false
    # Will only send notifications if status is higher than notify_level
    @notify_level = @opts.has_key?(:notify_level) ? @opts[:notify_level] : "WARNING"
    # remind_period to avoid too much noise
    @remind_period = @opts.has_key?(:remind_period) ? @opts[:remind_period] : 0
    ## Parameters from Check
    # Last status (for flapping/recovery detection)
    @last_status = @params.has_key?(:last_status) ? @params[:last_status] : "OK"
    # data dir
    @data_dir = @params.has_key?(:data_dir) ? @params[:data_dir] : nil
    ## Read persistent data
    @classname=self.class.name.sub("Rasca::","")
    @persist=readData(name,@classname)
    puts YAML.dump(@persist) if @debug
    @last_notification=@persist.has_key?(:last_notification) ? @persist[:last_notification] : 0
    puts "now:#{Time.now.to_i} last:#{@last_notification} remind: #{@remind_period}" if @debug

    # Initializes UsesPersistentData
    @data_dir=@params.has_key?(:data_dir) ? @params[:data_dir] : DEFAULT_DATA_DIR
    UsesPersistentData.instance_method(:initialize).bind(self).call(@data_dir)

  end
  # Returns true if sent or false if not sent 
  def notify(status,short,long)
    if STATES.include? status
      puts "now:#{Time.now.to_i} last:#{@last_notification} remind: #{@remind_period}" if @debug
      # When to send notifications:
      # - On status recovery: (status < last_status) ALWAYS
      # - On same status: (status = last_status) only if status > notify_level and remind_period has passed
      # - On status change up: (status > last_status) only if status > notify_level
      # - remind_period is only aplicable if there is no status change
      # - Special case flapping:
      #   - Critical -> Noticy (set las notification)
      #   - Recover -> Notify
      #   - Critical -> Should Notify, even if remind_period has not expired.  Otherwise last notification said everything 
      #   was OK. Can we do ir setting last_notification=0 on status recovery? If service is flapping, don't recover, 
      #   keep it in the highest status (in check)
      # 
      # Unless we are recovering, we apply some exclusion conditions to not send notification
      # (When recovering we ALWAYS notify)
      if STATES.index(status) < STATES.index(@last_status) 
        # No exclusion
      elsif STATES.index(status) == STATES.index(@last_status)
        # Do NOT notify if status is lower than notify_level
        if STATES.index(status) < STATES.index(@notify_level)
          puts "#{STATES.index(status)} < #{STATES.index(@notify_level)}" if @debug
          return false
        # Do NOT notify if last notification was sent more recently than :remind_period
        elsif Time.now.to_i < @last_notification + @remind_period
          puts "Next notification in: #{@remind_period - (Time.now.to_i - @last_notification)} seconds" if @debug
          return false
        end
      elsif STATES.index(status) > STATES.index(@last_status)
        if STATES.index(status) < STATES.index(@notify_level)
          puts "#{STATES.index(status)} < #{STATES.index(@notify_level)}" if @debug
          return false
        end
      end
      # No exclusion conditions where met. Send notification
      @persist[:last_notification] = Time.now.to_i
      send_notification(status,short,long)
      writeData(name,@classname)
      return true
    else
      raise "Unkown status: #{status}"
    end
  end
  # This is the method that really sends the notification and should be redefined for every notify method
  def send_notification(status,short,long)
    puts "Please, redefine method send_notify for this Class"
  end
end

# Notify with NSCA
class NotifyNSCA < Notify
  
  # Mapping between RASCA status and Nagios retcode
  NAGIOS_RETCODE = { "OK" => 0, "CORRECTED" => 0, "WARNING" => 1, "CRITICAL" => 2, "UNKNOWN" => 3}

  attr_accessor :server, :nsca_path, :nsca_conf
  def initialize(*args)
    super
    # NSCA host
    if @opts.has_key? :server
      @server=@opts[:server]
    else
      raise "ERROR: NSCA notification with no server specified"
    end
    # NSCA path
    @nsca_path = @opts.has_key?(:nsca_path) ? @opts[:nsca_path] : "/usr/sbin/send_nsca"
    @nsca_conf = @opts.has_key?(:nsca_conf) ? @opts[:nsca_conf] : "/etc/modularit/send_nsca.cfg"
    # This notification method send notifications ALWAYS
    @remind_period = 0
    @notify_level = "OK"
  end
  def send_notification(status,short,long)
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
class NotifyEMail < Notify
  attr_accessor :address, :mail_cmd
  def initialize(*args)
    super
    # Initialize default values
    @address = @opts.has_key?(:address) ? @opts[:address] : "root@localhost"
    @mail_cmd = @opts.has_key?(:mail_cmd) ? @opts[:mail_cmd] : "/usr/sbin/sendmail -t"
  end
  # Send email
  # Returns true if sent or false if not sent 
  def send_notification(status,short,long)
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

# Send report via Syslog
class NotifySyslog < Notify
  # Returns true if sent or false if not sent because status is lower than syslog_level
  def send_notification(status,short,long)
    # Open Syslog
    Syslog.open("Rasca::#{@name}", Syslog::LOG_CONS) do |l|
      l.log(Syslog::LOG_CRIT,"#{status} #{short}")
    end
  end
end

# Just print message
class NotifyPrint < Notify
  def send_notification(status,short,long)
    puts @client
    puts @name+": "+status+" "+short
    puts "--"
    puts long
  end
end

end # module Rasca
