module Rasca

# TODO:
# Checks DuplicityVolume generated data (persists)
# Run DuplicityVolume's col command and check result. Check against configured data

# A Simple Template
class CheckDuplicity < Check
  def initialize(*args)
    super

    ## Initialize config variables
    # Default check status when backups fail (can be overriden per vault in object file)
    @default_failed_status=@config_values.has_key?(:default_failed_status) ? @config_values[:default_failed_status] : "CRITICAL"   
    # Consider failed backup if last good backup is older than this (hours). Default: 36
    @default_expiration=@config_values.has_key?(:default_expiration) ? @config_values[:default_expiration] : 36*60*60

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
    # Default expiration
    expiration=@default_expiration
    # Default failed status
    failed_status=@default_failed_status

    puts "Checking volume: #{volume}" if @verbose

    if @objects.has_key?(volume)
      vol=DuplicityVolume.new(volume,@config_values,@objects[volume])
      vol.debug=@debug
      vol.testing=@testing
      vol.run("col")

      puts " Checking vol: #{volume} last backup: #{vol.last_backup}" if @verbose
      expiration=@objects[volume][:expiration] if @objects[volume].has_key? :expiration
	    puts "  expiration for #{volume} is #{expiration}" if @debug
      failed_status=@objects[volume][:failed_status] if @objects[volume].has_key? :failed_status
	    puts "  failed_status for #{vol.name} is #{failed_status}" if @debug
      # Check backup age
      if vol.last_backup
        if Time.now > vol.last_backup + expiration.to_i
          @short+="#{vol.name} OLD, "
          @long+="#{vol.name} is too OLD\n"
          incstatus(failed_status)
        else
          # OK, update last_known_good symlink
          incstatus("OK")
        end
      else
          @short+="no backups for #{vol.name}, "
          @long+="No backups found for volume #{vol.name}\n"
          incstatus(failed_status)
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

- Check last good backup is not older than limit for that vault
- Check that vault is not empty

TODO:
- Get stats from log and
  - Check the deviation from the average is not over limit

== Parameters in config file

  :default_failed_status: Status of alert if any backup failed. Default: WARNING
  :default_expiration: Consider failed backup if last good backup is older than this (hours). Default: 36

== Objects format

  vault:
    :failed_status: status to set if this backup failed. Default: default_failed_status
    :expiration: expiration time in seconds. Only consider failed if last valid backup is older than this. Default: default_expiration

Example:

critical_backup:
  :failed_status: CRITICAL
  :expiration: 12

]    
  end
end

end # module Rasca
