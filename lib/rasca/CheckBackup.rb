module Rasca

# A Simple Template
class CheckBackup < Check
  def initialize(*args)
    super

    # Initialize config variables
    @log_dir=@config_values.has_key?(:log_dir) ? @config_values[:log_dir] : "/var/lib/pica/obj/lastbackups"
    @default_expiration=@config_values.has_key?(:default_expiration) ? @config_values[:default_expiration] : 4*24*60*60
    @backup_skip_all=@config_values.has_key?(:backup_skip_all) ? @config_values[:backup_skip_all] : nil

    # More initialization
    #
  end
  # The REAL Check
  def check
    # Check if we are configured to skip all backup checks
    if @backup_skip_all
      incstatus("OK")
      @short=@backup_skip_all
      return
    end

    ## Not skipped, we check backups
    @objects=readObjects(@name)

    puts "Objects"
    puts YAML.dump(@objects)
        
    out=""
    if @testing
      # Use testing input (for unit testing)
      out=@testing.split("\n")
    else
      # Use REAL input
      # FIXME: We only check LVM volumes
      out=`lvscan | grep -v swap | grep -v snap_`
    end

    ## CHECK CODE 
    # Start setting status=OK because we may not have enything to check
    incstatus("OK")
    out.each do |line|
      expiration=@default_expiration
      skip=false
      line.chomp!
      if line =~ /^.*'(.*)'.*$/
        lv = File.basename($1)
        puts "LV: "+lv if @debug
        # Fixme: Check for skip
        if @objects.has_key? lv
          # Ok, we have an entry, If entry is a hash, read parameters
          if @objects[lv].instance_of?Hash 
            expiration=@objects[lv][:expiration] if @objects[lv].has_key? :expiration
          else
            # If it's not a has, just skip
            puts "Skipping #{lv}" if @debug
            skip=true
          end
        end
        unless skip
          if File.exist? "#{@log_dir}/#{lv}"
            puts "logfile for #{lv} exists, good!" if @debug
            mtime=File.stat("#{@log_dir}/#{lv}").mtime
            puts "mtime : "+mtime.to_s if @debug
            if (Time.now - mtime) > expiration
              puts "OLD backup of #{lv}" if @debug
              @short+="OLD bcklog for #{lv},"
              @long+="Backup of #{lv} id too old"
              incstatus("WARNING")
            else
              incstatus("OK")
            end
          else
            puts "  WARNING: no logfile for #{lv}\n" if @debug
            @short+="no bcklog for #{lv},"
            @long+="Never seen a backup of #{lv}\n"
            incstatus("WARNING")
          end
        end
      end
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end
  def info
    %[
== Description

Checks if we have recent backups of all LVM volumes

FIXME: Only checks LVM, we also need filesystems. CHANGES needed:

0. Add an option skip_all to show that we backup some othr way:

skip_all: Backup of volumes in dom0

1. Before checking /var/lib/pica/obj/lastbackups we will check for /var/lib/modularit/data/BackupChk. If it doesn't exist, fall back to /var/lib/pica/obj/lastbackups.
2. If it exists, use that one (in YAML)
3. After checking the LV, check the filesystems. If we configure that a filesistem uses a LV, check using the VG/LV

== Parameters in config file

  :log_dir: Directory for backup timestamps. Default: /var/lib/pica/obj/lastbackups
  :default_expiration: Default expiration limit in seconds. Default: 4*24*60*60

== Objects format

  volume:
    :expiration: expiration time in seconds. 

If we only specify the volume, just skip that volume from checks

Example:

dom0_opt:
dom0_var:
  :expiration: 172800

]    
  end
end

end # module Rasca
