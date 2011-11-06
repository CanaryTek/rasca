module Rasca

# This package implements notifications using different methods
#
# Nagios: Works as a Nagios plugin
# Print: prints
# nsca: Nagios NSCA alert
# syslog

# Generic notification class
# On creation we have to pass a Hash of methods and destinations
# The destination depends on the notification type:
# { :print => nil, :nsca => "nsca_server"}
#
class Notification
  attr_accessor :long, :short
  attr_reader :notifications

  def initialize(name,methods)
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
          @notifications.push(NotifyPrint.new(name))
        when :nsca
          @notifications.push(NotifyNSCA.new(name,dest))
        else
          raise "Unknown notyfication method: #{type.to_s}"
      end
    end

    # Send notifications using all methods
    def send
      @notifications.each do |method|
        method.notify(@short,@long)
      end
    end

  end

end

# Notifify with NSCA
class NotifyNSCA
  attr_accessor :server
  def initialize(name,server)
    @name=name
    @server=server
  end
  def notify(short,long)
    puts "nsca #{server} #{short}"
  end
end

# Just print message
class NotifyPrint 
  def initialize(name)
    @name=name
  end
  def notify(short,long)
    puts long
  end
end


end # module Rasca
