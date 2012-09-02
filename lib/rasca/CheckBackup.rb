module Rasca

# A Simple Template
class CheckBackup < Check
  attr_accessor :testing1, :testing2

  def initialize(*args)
    super

    # Initialize config variables
    @log_dir=@config_values.has_key?(:log_dir) ? @config_values[:log_dir] : "/var/lib/modularit/data/lastbackups"
    @default_expiration=@config_values.has_key?(:default_expiration) ? @config_values[:default_expiration] : 4*24*60*60
    @backup_skip_all=@config_values.has_key?(:backup_skip_all) ? @config_values[:backup_skip_all] : nil
    @skip_fs_regex=@config_values.has_key?(:skip_fs_regex) ? @config_values[:skip_fs_regex] : /^Filesystem|^tmpfs|^rootfs|^devtmpfs/

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

    # Create logdir if it doesn't exist
    FileUtils.mkdir_p @log_dir unless File.directory? @log_dir

    ## Initialize to OK since we may skip everything
    incstatus("OK")

    ## CHECK CODE 
    check_lv
    check_fs

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end

  ## Checks found LVs for backups
  def check_lv
    out=""
    if @testing1
      # Use testing input (for unit testing)
      out=@testing1.split("\n")
    else
      # Use REAL input
      out=`lvscan | grep -v swap | grep -v snap_`
    end
    out.each do |line|
      line.chomp!
      if line =~ /^.*'(.*)'.*$/
        lv = File.basename($1)
        puts "LV: "+lv if @debug
        check_entry(lv)     
      end
    end
  end

  # Checks found filesystems for backups
  def check_fs
    out=""
    if @testing2
      # Use testing input (for unit testing)
      out=@testing2.split("\n")
    else
      # Use REAL input
      # FIXME: Use a more robust way to list filesystems
      out=`df`
    end
    out.each do |line|
      line.chomp!
      next if line.match @skip_fs_regex
      puts "line: #{line}"
      fs=line.split.last
      puts "FS: "+fs if @debug
      check_entry(fs)     
    end
  end

  # Checks the given entry (lv or filesystem) to see if we have a backup timestamp
  def check_entry(entry)
    expiration=@default_expiration
    skip=false
    name=entry.gsub("/","_")
    if @objects.has_key? entry
      # Ok, we have an entry, If entry is a hash, read parameters
      if @objects[entry].instance_of?Hash 
        expiration=@objects[entry][:expiration] if @objects[entry].has_key? :expiration
        name=@objects[entry][:name] if @objects[entry].has_key? :name
      else
        # If it's not a has, just skip
        puts "Skipping #{entry}" if @debug
        skip=true
      end
    end
    unless skip
      if File.exist? "#{@log_dir}/#{name}"
        puts "logfile for #{entry} exists, good!" if @debug
        mtime=File.stat("#{@log_dir}/#{name}").mtime
        puts "mtime : "+mtime.to_s if @debug
        if (Time.now - mtime) > expiration
          puts "OLD backup of #{entry}" if @debug
          @short+="OLD bcklog for #{entry},"
          @long+="Backup of #{entry} id too old"
          incstatus("WARNING")
        else
          incstatus("OK")
        end
      else
        puts "  WARNING: no logfile for #{entry}\n" if @debug
        @short+="no bcklog for #{entry},"
        @long+="Never seen a backup of #{entry}\n"
        incstatus("WARNING")
      end
    end
  end
  def info
    %[
== Description

Checks if we have recent backups of all LVM volumes and/or filesystems

== Parameters in config file

  :log_dir: Directory for backup timestamps. Default: /var/lib/modularit/data/lastbackups
  :default_expiration: Default expiration limit in seconds. Default: 4*24*60*60
  :skip_all: Skip all backup checks and set status OK and return the message specified by this option.
  :skip_fs_regex: Regex used for filesystems to skip. Default: /^Filesystem|^tmpfs|^rootfs|^devtmpfs/

== Objects format

  volume:
    :expiration: expiration time in seconds. 
    :name: name to look for in log dir. In filesystems we change / for _ (/var -> _var, / -> _) but we can override this whoth the :name options 

If we only specify the volume, just skip that volume from checks

Example:

dom0_opt:
dom0_var:
  :expiration: 172800
/:
  :name: root

]    
  end
end

end # module Rasca
