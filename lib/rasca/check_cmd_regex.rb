module Rasca
# Apply regex checks to a command output
class CheckCmdRegex < Check
  def initialize(*args)
    super
  end
  def check
    # Read Objects
    readObjects(@name)
    # If nothing to check, status should be OK
    incstatus("OK")
    
    @objects.keys.each do |obj|
      # Set defaults
      next unless @objects[obj].is_a?Hash
      # Make sure we have all mandatory keys
      next unless @objects[obj].has_key?(:command) and @objects[obj].has_key?(:regex) and @objects[obj].has_key?(:status)
      @command=@objects[obj][:command]
      @regex=@objects[obj][:regex]
      @mystatus=@objects[obj][:status]
      # Override with object parameters
      @status_on_cmd_fail=@objects[obj].has_key?(:status_on_cmd_fail) ? @objects[obj][:status_on_cmd_fail] : "UNKNOWN"
      @message=@objects[obj].has_key?(:message) ? @objects[obj][:message] : "Regex found for test#{obj}"
      puts "Checking obj: #{obj}: #{@command} #{@regex} #{@mystatus}" if @debug
      output=`#{@command} 2>&1`
      puts "output\n#{output}" if @debug
      if $?.success?
        if output.match(Regexp.new @regex)
          # Found
          incstatus(@mystatus)
          puts "FOUND: regex for test #{obj}" if @debug
          @short+="#{obj} regex match, "
          @long+="Regex for #{obj} found\n"
        else
          puts "NOOOT FOUND: regex for test #{obj}" if @debug
          @short+="#{obj} cmd failed, "
        end
      else
        # Command error
          puts "COMMAND FAILED for test #{obj} setting #{@status_on_cmd_fail}" if @debug
          setstatus(@status_on_cmd_fail)
      end
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="All regex checks ok" 
    end
  end
  def info
    %[
== Description

Apply regular expressions to command output, and set status according to configuration

== Parameters in config file

== Objects format

Objects dir: #{@object_dir}/#{@name}

  test:
    :command: Command to run. MANDATORY
    :regex: Regex to apply. MANDATORY
    :status: Status to set if regex found. MANDATORY
    :status_on_cmd_fail: Status to set if command fails. Default: UNKNOWN
    :message: Message to send if regex found. Default: $test regex found

  Example:

ipmi-disk:
  :command: ipmi sel list
  :regex: /disk deasserted/
  :status: WARNING
  :status_on_cmd_fail: OK
  :message: A disk may be failing. Run "ipmi sel list"
ipmi-error:
  :command: ipmi sel list
  :regex: /error/
  :status: WARNING
  :message: Unknown IPMI error. Run "ipmi sel list"
]
  end

end

end # module Rasca
