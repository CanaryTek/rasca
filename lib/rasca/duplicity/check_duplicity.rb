module Rasca

# TODO:
# Checks DuplicityVolume generated data (persists)
# Run DuplicityVolume's col command and check result. Check against configured data

# A Simple Template
class CheckDuplicity < Check

  DEFAULT={
    :warning_limit => 36*60*60,
    :critical_limit => 50*60*60,
    :nobackup_status => "CRITICAL"
  }

  def initialize(*args)
    super

    ## Initialize config variables
    # Backup age limit to set status to WARNING
    @warning_limit=@config_values.has_key?(:warning_limit) ? @config_values[:warning_limit] : DEFAULT[:warning_limit]
    # Backup age limit to set status to CRITICAL
    @critical_limit=@config_values.has_key?(:critical_limit) ? @config_values[:critical_limit] : DEFAULT[:critical_limit]
    # Status to set if no backup for a volume
    @nobackup_status=@config_values.has_key?(:nobackup_status) ? @config_values[:nobackup_status] : DEFAULT[:nobackup_status]

    # More initialization
    #
  end
  # The REAL Check
  def check
    @objects=readObjects("backup")
    
    if @testing
      # Use testing input (for unit testing)
    else
      # Use REAL input
    end

    ## CHECK CODE 
    # Set OK if no objects to check
    incstatus("OK") if @objects.empty?
    # Checks all volumes
    @objects.keys.each do |volume|
      check_volume(volume)
    end
 
    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end

  # Checks a volume for correct backups
  def check_volume(volume) 
    # Default warning_limit
    warning_limit=@warning_limit
    # Default critical_limit
    critical_limit=@critical_limit
    # Default nobackup_status
    nobackup_status=@nobackup_status

    puts "Checking volume: #{volume}" if @verbose

    if @objects.has_key?(volume)
      vol=DuplicityVolume.new(volume,@config_values,@objects[volume])
      vol.debug=@debug
      vol.testing=@testing
      vol.run("col")

      puts " Checking vol: #{volume} last backup: #{vol.last_backup}" if @verbose
      warning_limit=@objects[volume][:warning_limit] if @objects[volume].has_key? :warning_limit
	    puts "  warning_limit for #{volume} is #{warning_limit}" if @debug
      critical_limit=@objects[volume][:critical_limit] if @objects[volume].has_key? :critical_limit
	    puts "  critical_limit for #{volume} is #{critical_limit}" if @debug
      nobackup_status=@objects[volume][:nobackup_status] if @objects[volume].has_key? :nobackup_status
	    puts "  nobackup_status for #{volume} is #{nobackup_status}" if @debug
      # Check backup age
      check_time=Time.now
      if vol.last_backup
        if check_time < vol.last_backup + warning_limit.to_i
          incstatus("OK")
        elsif check_time >= vol.last_backup + warning_limit.to_i and check_time < vol.last_backup + critical_limit.to_i
          @short+="#{vol.name} OLD, "
          @long+="#{vol.name} is too OLD\n"
          incstatus("WARNING")
        elsif check_time >= vol.last_backup + critical_limit.to_i
          @short+="#{vol.name} OLD, "
          @long+="#{vol.name} is too OLD\n"
          incstatus("CRITICAL")
        end
      else
          @short+="no backups for #{vol.name}, "
          @long+="No backups found for volume #{vol.name}\n"
          incstatus(nobackup_status)
      end
    else
      puts "ERROR: Volume #{volume} is not defined"
      return false
    end
  end
  # Prints usage info
  def info
    %[
== Description

Checks duplicity backups to make sure we have up to date backups:

- If a defined vault does not have backups, sets status to CRITICAL
- If the backup is old, it sets status according to warning_limit and critical_limit (see below)
- Check that vault is not empty

TODO:
- Tener 2 umbrales con valores por defecto: warning_limit (36 horas) y critical_limit (50h) en segundos
- Si edad_copia < warning_limit -> OK
- Si warning_limit <= edad_copia < critical_limit -> WARNING
- Si edad_copia >= critical_limit -> CRITICAL

Casos especiales:

- Si queremos que pase directamente a CRITICAL, hacer que warning_limit = critical_limit
- Si queremos que siempre sea WARNING (nunca CRITICAL) Ponemos un critical MUY alto???
- Si queremos que siempre sea OK (no queremos monitorizar las copias??) Lo mejor seria saltarnos ese volumen

TODO:
- Get stats from log and
  - Check the deviation from the average is not over limit

== Parameters in config file

  :warning_limit: Backup age limit to set status to WARNING (in seconds). Default: #{DEFAULT[:warning_limit]}
  :critical_limit: Backup age limit to set status to CRITICAL (in seconds). Default: #{DEFAULT[:critical_limit]}
  :nobackup_status: Status to set if no backup found for a volume. Default: #{DEFAULT[:nobackup_status]}

== Objects format

  vault:
    :warning_limit: Backup age limit to set status to WARNING (in seconds).
    :critical_limit: Backup age limit to set status to CRITICAL (in seconds).
    :nobackup_status: Status to set if no backup found for this volume. Default: #{DEFAULT[:nobackup_status]}

Example:

critical_backup:
  :warning_limit: 172800 # 48 hours
  :critical_limit: 180000 # 50 hours

]    
  end
end

end # module Rasca
