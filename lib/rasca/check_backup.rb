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
    @skip_fs_regex=@config_values.has_key?(:skip_fs_regex) ? @config_values[:skip_fs_regex] : / sysfs | tmpfs | rootfs | devtmpfs | proc | rpc_pipefs | binfmt_misc | devpts /

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
    @objects=readObjects("backup")

    # Create logdir if it doesn't exist
    FileUtils.mkdir_p @log_dir unless File.directory? @log_dir

    ## Initialize to OK since we may skip everything
    incstatus("OK")

    ## CHECK CODE 
    entries=Array.new
    # Add mount entries
    entries=list_fs
    puts YAML.dump(entries) if @debug
    # Add lv entries if not already in mount entries
    list_lv.keys.each do |lv|
      puts "looking for key #{lv} #{convert_to_mapper(lv)} #{convert_from_mapper(lv)}" if @debug
      #unless entries.include?(key) or entries.include?(convert_to_mapper(key)) or entries.include?(convert_from_mapper(key))
      unless entries.include?(convert_to_mapper(lv))
        entries[lv]=nil
      end
    end
    puts YAML.dump(entries) if @debug
    entries.keys.each do |dev|
      mount=entries[dev]
      # First: Look for mount
      if mount and check_entry(mount) 
        puts "found #{mount}" if @debug
      # Then check for dev
      elsif check_entry(File.basename(dev))
        puts "found #{dev}" if @debug
      # Then check for mapper translated dev
      else check_entry(convert_to_mapper(dev))
        puts "found #{File.basename(convert_to_mapper(dev))}" if @debug
      end
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end

  # Convert name to mapper (ex: /dev/vg_sys/lv_root -> /dev/mapper/vg_sys-lv_root)
  def convert_to_mapper(name)
    c=name.split("/")
    vg=c[2]
    lv=c[3]
    "/dev/mapper/#{vg}-#{lv}"
  end 

  # Convert name from mapper (ex: /dev/mapper/vg_sys-lv_root -> /dev/vg_sys/lv_root)
  def convert_from_mapper(name)
    if name.match(/\/dev\/mapper/)
      v=name.split("/")
      c=v[3].split("-")
      vg=c[0]
      lv=c[1]
      "/dev/#{vg}/#{lv}"
    else
      name
    end
  end 

  ## List logical volumes
  def list_lv
    out=""
    devs=Hash.new
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
        #lv = File.basename($1)
        lv = $1
        puts "lv: #{lv}" if @debug
        devs[lv]=nil
      end
    end
    devs
  end

  ## Returns a list of devices and where they are monted
  def list_fs
    out=""
    devs=Hash.new
    if @testing2
      # Use testing input (for unit testing)
      out=@testing2.split("\n")
    else
      # Use REAL input
      # FIXME: Use a more robust way to list filesystems
      out=`mount`
    end
    out.each do |line|
      line.chomp!
      next if line.match @skip_fs_regex
      c=line.split(" ")
      dev=c[0]
      fs=c[2]
      puts "#{dev} mounted on #{fs}" if @debug
      devs[dev]=fs
    end
    devs
  end

  # Checks the given entry (lv or filesystem) to see if we have a backup timestamp
  def check_entry(entry)
    found=false
    expiration=@default_expiration
    skip=false
    name=entry.gsub("/","_")
    puts "Checking backups for #{entry}" if @debug
    if @objects.has_key? entry
      # Ok, we have an entry, If entry is a hash, read parameters
      if @objects[entry].instance_of?Hash 
        expiration=@objects[entry][:expiration] if @objects[entry].has_key? :expiration
        name=@objects[entry][:name] if @objects[entry].has_key? :name
        if @objects[entry].has_key? :skip
          puts "Skipping #{entry}: #{@objects[entry][:skip]}" if @debug
          skip=true
          # We want to skip, so do not check with other names
          found=true
        end
      else
        # If it's not a hash, just skip
        puts "Skipping #{entry}" if @debug
        skip=true
        # We want to skip, so do not check with other names
        found=true
      end
    end
    unless skip
      puts "Checking file #{@log_dir}/#{name}" if @debug
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
          found=true
          incstatus("OK")
        end
      else
        puts "  WARNING: no logfile for #{entry}\n" if @debug
        @short+="no bcklog for #{entry},"
        @long+="Never seen a backup of #{entry}\n"
        incstatus("WARNING")
      end
    end
    found
  end
  def info
    %[
== Description

Checks if we have recent backups of all LVM volumes and/or filesystems

TODO: We should integrate CheckDuplicity into this alarm

- Buscar el volumen (completo) en el objects
- Buscar el fichero con el nombre "traducido"
- OJO: en el antiguo BackupChk solo se especificaba el lv, sin VG (dom0_var en lugar de /dev/sys/dom0_var)
- Si no lo tiene, bucarlo por el nombre devmapper
- Si no lo tiene, buscarlo por el mount (a partir del nombre mapper)

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
