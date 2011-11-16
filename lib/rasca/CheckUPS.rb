module Rasca

# A Simple Template
class CheckUPS < Check
  def initialize(*args)
    super

    # Initialize config variables
    @upsconf=@config_values.has_key?(:upsconf) ? @config_values[:upsconf] : "/etc/ups/upsmon.conf"

    # More initialization
    #
  end
  # The REAL Check
  def check
    @objects=readObjects(@name)
    ups=nil
    
    if @testing
      # Use testing input (for unit testing)
    else
      # Use REAL input
    end

    ## CHECK CODE 
    File.open(@upsconf).each do |line|
      if line =~ /^MONITOR (\w+@\w+)/
        ups=$1
      end
    end

    if ups
      output=`upsc #{ups} ups.status 2>&1`
      unless $?.success?
        incstatus("WARNING")
        @short="Error running upsc"
        @long=output
      else
        if output =~ /RB.*/
          incstatus("WARNING")
          @short="UPS Replace Battery"
          @long="UPS Battery needs to be replaced\n"
        elsif output =~ /OL.*/
          incstatus("OK");
          @short="UPS on line power"
          @long="UPS running on line power. OK\n"
        elsif output =~ /OB.*/
          incstatus("CRITICAL")
          @short="UPS on Battery"
          @long="UPS running on battery!. FIX ASAP\n"
        else
          incstatus("WARNING")
          @short="UPS on unknown status"
          @long="UPS on UNKNOWN status"
        end
      end
    else
      puts "No UPS found" if @debug
      incstatus("WARNING")
      @short="No UPS found to monitor"
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end
  def info
    %[
== Description

Checks the status of the UPS

== Parameters in config file

  :upsconf: UPS config file

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
