module Rasca

require 'time'

# Checks SafeKeep backup server status
class CheckSafekeep < Check

  DEFAULT={
    :target_dir => "/etc/safekeep/backup.d",
    :warning_limit => 36*60*60,
    :critical_limit => 50*60*60,
    :nobackup_status => "CRITICAL"
  }

  def initialize(*args)
    super

    ## Initialize config variables
    # SafeKeep target dir
    @target_dir=@config_values.has_key?(:target_dir) ? @config_values[:target_dir] : DEFAULT[:target_dir]
    # Backup age limit to set status to WARNING
    @warning_limit=@config_values.has_key?(:warning_limit) ? @config_values[:warning_limit] : DEFAULT[:warning_limit]
    # Backup age limit to set status to CRITICAL
    @critical_limit=@config_values.has_key?(:critical_limit) ? @config_values[:critical_limit] : DEFAULT[:critical_limit]
    # Status to set if no backup for a target
    @nobackup_status=@config_values.has_key?(:nobackup_status) ? @config_values[:nobackup_status] : DEFAULT[:nobackup_status]

    # More initialization
    #
  end
  # The REAL Check
  def check
     puts "CheckSafekeep" if @debug
    @objects=readObjects("CheckSafekeep")
    
    if @testing
      # Use testing input (for unit testing)
    else
      # Use REAL input
    end

    ## CHECK CODE
    @targets=Dir.glob("#{@target_dir}/*.backup").map{ |x| File.basename(x).gsub(/\.backup/,"") }.sort
    # Set OK if no objects to check
    if @targets.empty?
       incstatus("WARNING")
       @short="No backup targets found"
       puts "No backup targets found" if @debug
    end
    # Checks all targets
    @targets.each do |target|
      check_target(target)
    end
 
    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end

  def current_mirror(target)
	@out=`safekeep --list #{target} 2>&1`
	if @out.grep(/Current mirror:/).last
	  tstamp=@out.grep(/Current mirror:/).last.gsub(/^.*Current mirror:/,"")
	  time=Time.parse(tstamp)
	  puts "Last backup: #{time}" if @debug
	  time
	else
	  puts "No backups for #{target}" if @debug
	  nil
	end
  end

  # Checks a target for correct backups
  def check_target(target) 
    # Default warning_limit
    warning_limit=@warning_limit
    # Default critical_limit
    critical_limit=@critical_limit
    # Default nobackup_status
    nobackup_status=@nobackup_status

    puts "Checking target: #{target}" if @verbose

    if @objects.has_key?(target)
      # Return if target marked as skip
      return if @objects[target].has_key?(:skip)

      # Set target limits if given
      warning_limit=@objects[target][:warning_limit] if @objects[target].has_key? :warning_limit
      puts "  warning_limit for #{target} is #{warning_limit}" if @debug
      critical_limit=@objects[target][:critical_limit] if @objects[target].has_key? :critical_limit
      puts "  critical_limit for #{target} is #{critical_limit}" if @debug
      nobackup_status=@objects[target][:nobackup_status] if @objects[target].has_key? :nobackup_status
      puts "  nobackup_status for #{target} is #{nobackup_status}" if @debug
    end
    # Check backup age
    check_time=Time.now
    last_backup=current_mirror(target)
    if last_backup
      if check_time < last_backup + warning_limit.to_i
        incstatus("OK")
      elsif check_time >= last_backup + warning_limit.to_i and check_time < last_backup + critical_limit.to_i
        @short+="#{target} OLD, "
        @long+="#{target} is too OLD\n"
        incstatus("WARNING")
      elsif check_time >= last_backup + critical_limit.to_i
        @short+="#{target} OLD, "
        @long+="#{target} is too OLD\n"
        incstatus("CRITICAL")
      end
    else
        @short+="no backups for #{target}, "
        @long+="No backups found for target #{target}\n"
        incstatus(nobackup_status)
    end
  end
  # Prints usage info
  def info
    %[
== Description

Checks safekeep backups to make sure we have up to date backups:

- If a defined target does not have backups, sets status to CRITICAL
- If the backup is old, it sets status according to warning_limit and critical_limit (see below)
- Check that backup is not empty

TODO:
- Tener 2 umbrales con valores por defecto: warning_limit (36 horas) y critical_limit (50h) en segundos
- Si edad_copia < warning_limit -> OK
- Si warning_limit <= edad_copia < critical_limit -> WARNING
- Si edad_copia >= critical_limit -> CRITICAL

Casos especiales:

- Si queremos que pase directamente a CRITICAL, hacer que warning_limit = critical_limit
- Si queremos que siempre sea WARNING (nunca CRITICAL) Ponemos un critical MUY alto???
- Si queremos que siempre sea OK (no queremos monitorizar las copias??) Lo mejor seria saltarnos ese target

TODO:
- Get stats from log and
  - Check the deviation from the average is not over limit

== Parameters in config file

  :warning_limit: Backup age limit to set status to WARNING (in seconds). Default: #{DEFAULT[:warning_limit]}
  :critical_limit: Backup age limit to set status to CRITICAL (in seconds). Default: #{DEFAULT[:critical_limit]}
  :nobackup_status: Status to set if no backup found for a target. Default: #{DEFAULT[:nobackup_status]}

== Objects format

  target:
    :warning_limit: Backup age limit to set status to WARNING (in seconds).
    :critical_limit: Backup age limit to set status to CRITICAL (in seconds).
    :nobackup_status: Status to set if no backup found for this target. Default: #{DEFAULT[:nobackup_status]}
    :skip: Skip this target (write the reason)

Example:

critical_backup:
  :warning_limit: 172800 # 48 hours
  :critical_limit: 180000 # 50 hours
  :skip: temporarily disabled

]    
  end
end

end # module Rasca
