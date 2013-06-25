module Rasca

# A Simple Template
class CheckBackup < Check

  DEFAULT={
    :log_dir => "/var/lib/modularit/data/lastbackups",
    :fs_types_cmd => "grep -v nodev /proc/filesystems",
    :lvscan_cmd => "lvscan | grep -v swap | grep -v snap_",
    :mount_cmd => "mount",
    :skip_fs_regex => "iso9660|fuseblk",
    :warning_limit => 2*24*60*60,
    :critical_limit => 7*24*60*60,
  }

  attr_accessor :testing1, :testing2, :log_dir, :backup_skip_all,  :default_expiration, :fs_types_cmd, :lvscan_cmd, :mount_cmd, :skip_fs_regex

  def initialize(*args)
    super

    # Initialize config variables
    @log_dir=@config_values.has_key?(:log_dir) ? @config_values[:log_dir] : DEFAULT[:log_dir]
    @backup_skip_all=@config_values.has_key?(:backup_skip_all) ? @config_values[:backup_skip_all] : nil
    @backup_skip_lvscan=@config_values.has_key?(:backup_skip_lvscan) ? @config_values[:backup_skip_lvscan] : false
    @backup_skip_mounts=@config_values.has_key?(:backup_skip_mounts) ? @config_values[:backup_skip_mounts] : false
    @fs_types_cmd=@config_values.has_key?(:fs_types_cmd) ? @config_values[:fs_types_cmd] : DEFAULT[:fs_types_cmd]
    @lvscan_cmd=@config_values.has_key?(:lvscan_cmd) ? @config_values[:lvscan_cmd] : DEFAULT[:lvscan_cmd]
    @mount_cmd=@config_values.has_key?(:mount_cmd) ? @config_values[:mount_cmd] : DEFAULT[:mount_cmd]
    @skip_fs_regex=@config_values.has_key?(:skip_fs_regex) ? @config_values[:skip_fs_regex] : DEFAULT[:skip_fs_regex]
    @warning_limit=@config_values.has_key?(:warning_limit) ? @config_values[:warning_limit] : DEFAULT[:warning_limit]
    @critical_limit=@config_values.has_key?(:critical_limit) ? @config_values[:critical_limit] : DEFAULT[:critical_limit]

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
    entries=Hash.new
    # Add mount entries
    entries=get_mounts_to_backup(entries) unless @backup_skip_mounts
    entries=get_lvs_to_backup(entries) unless @backup_skip_lvscan
    puts YAML.dump(entries) if @debug
    entries.values.each do |entry|
      check_entry(entry)
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end

  # Return a list of file system types to backup (by default from /proc/filesystems)
  def fs_types_to_backup
    regex=Regexp.new(@skip_fs_regex)
    fs=%x[#{fs_types_cmd}] 
    fs.split.reject {|x| regex =~ x}
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

  ## Returns a hash containing LV to backup
  # It will NOT duplicate any LV already present in the Hash passed as parameter
  # The key will be the device in devmapper syntax. ej:
  # { /dev/mapper/my_vg-my_lv => { :dev => "/dev/mapper/my_vg-my_lv", :mount => "/mnt", :fstype => "ext3" }}
  def get_lvs_to_backup(devs=Hash.new)
    out=%x[#{@lvscan_cmd}].split("\n")
    out.each do |line|
      line.chomp!
      if line =~ /^.*'(.*)'.*$/
        lv = $1
        puts "lv: #{lv}" if @debug
        unless devs.has_key?(lv) or devs.has_key?(convert_to_mapper(lv))
          devs[convert_to_mapper(lv)]={ :dev=>convert_to_mapper(lv), :lvname => lv}
        end
      end
    end
    devs
  end

  ## Returns a hash containing mounts to backup
  # The key will be the device in devmapper syntax. ej:
  # { /dev/mapper/my_vg-my_lv => { :dev => "/dev/mapper/my_vg-my_lv", :mount => "/mnt", :fstype => "ext3" }}
  def get_mounts_to_backup(devs=Hash.new)
    out=%x[#{@mount_cmd}].split("\n")
    out.each do |line|
      line.chomp!
      next unless line.match Regexp.new(fs_types_to_backup.join("|"))
      c=line.split(" ")
      dev=c[0]
      fs=c[2]
      fstype=c[4]
      puts "#{dev} mounted on #{fs} type #{fstype}" if @debug
      devs[dev]={ :dev => dev, :mount => fs, :fstype => fstype }
    end
    devs
  end

  # Get object entry for given mount
  # Search objects in this order: :mount, :dev, convert_from_mapper(:dev), basename(:dev), basename(convert_from_mapper(:dev))
  def get_object(entry)
    dev=entry[:dev]
    mount=entry[:mount]
    object=nil
    found=false
    [mount, dev, convert_from_mapper(dev), File.basename(dev), File.basename(convert_from_mapper(dev))].each do |obj|
      if @objects.has_key? obj
        puts "Found #{obj} in objects" if @debug
        object=@objects[obj]
        found=true
        break
      end
    end
    # If object==nil and found==true, the object was empty and it means we should skip it
    if found and object==nil
      puts "object was empty. skip it" if @debug
      object={:skip=>"Skipped"}
    end
    object
  end

  # Find backup timestamp file for a filesystem
  # Search file in this order: :mount, basename(:dev), basename(convert_from_mapper(:dev))
  def find_backup_tstamp(entry,name=nil)
    dev=entry[:dev]
    mount=entry[:mount].gsub("/","_") if entry.has_key? :mount
    tstamp_file=nil
    if name
      if File.exists? "#{@log_dir}/#{name}"
        puts "Found tstamp file #{@log_dir}/#{name}" if @debug
        tstamp_file="#{@log_dir}/#{name}"
      else
        nil
      end
    else
      [ mount, File.basename(dev), File.basename(convert_from_mapper(dev)) ].each do |file|
        if file and File.exists? "#{@log_dir}/#{file}"
          puts "Found tstamp file #{@log_dir}/#{file}" if @debug
          tstamp_file="#{@log_dir}/#{file}"
          found=true
          break 
        end
      end
      tstamp_file
    end
  end

  # Checks the given entry (lv or filesystem) to see if we have a backup timestamp
  def check_entry(entry)
    skip=false
    dev=entry[:dev]
    mount=entry[:mount]
    warning_limit=@warning_limit
    critical_limit=@critical_limit
    name=nil
    puts "Checking backups for dev:#{dev} mount:#{mount} name:#{name}" if @debug
    object=get_object(entry)
    if object
      puts "Found object: #{object}" if @debug
      # Ok, we have an entry, If entry is a hash, read parameters
      if object.instance_of?Hash 
        warning_limit=object[:warning_limit] if object.has_key? :warning_limit
        critical_limit=object[:critical_limit] if object.has_key? :critical_limit
        name=object[:name] if object.has_key? :name
        if object.has_key? :skip
          puts "Skipping #{dev}: #{object[:skip]}" if @debug
          skip=true
        end
      else
        # If it's not a hash, just skip
        puts "Skipping #{dev}" if @debug
        skip=true
      end
    end
    unless skip
      if tstamp_file=find_backup_tstamp(entry,name)
        mtime=File.stat(tstamp_file).mtime
        check_time=Time.now
        puts "Checking: #{dev}: " if @debug
        puts "  last_backup: #{mtime.to_s} check_time: #{check_time.to_s}" if @debug
        puts "  warning_time: #{mtime+warning_limit} critical_time: #{(mtime+critical_limit).to_s}" if @debug
        if check_time < mtime + warning_limit.to_i
          incstatus("OK")
        elsif check_time >= mtime + warning_limit.to_i and check_time < mtime + critical_limit.to_i
          @short+="#{dev} backup OLD, "
          @long+="backup of #{dev} is too OLD\n"
          incstatus("WARNING")
        elsif check_time >= mtime + critical_limit.to_i
          @short+="#{dev} backup critical OLD, "
          @long+="backup of #{dev} is critically OLD\n"
          incstatus("CRITICAL")
        end
      else
        # FIXME: No backup is CRITICAL!"
        puts "  WARNING: no logfile for #{dev}\n" if @debug
        @short+="no bcklog for #{dev},"
        @long+="Never seen a backup of #{dev}\n"
        incstatus("WARNING")
      end
    end
  end
  def info
    %[
== Description

Checks if we have recent backups of all LVM volumes and/or filesystems

== Parameters in config file

  :log_dir: Directory for backup timestamps. Default: #{DEFAULT[:log_dir]}
  :backup_skip_all: Skip all backup checks and set status OK and return the message specified by this option.
  :backup_skip_lvscan: Skip LVM logical volumes from backup checks.
  :backup_skip_mounts: Skip mounts from backup checks (check only LVM).
  :fs_types_cmd: Command to get filesystem types to backup. Default: #{DEFAULT[:fs_types_cmd]}
  :lvscan_cmd: Command to get LV list. Default: #{DEFAULT[:lvscan_cmd]}
  :mount_cmd: Command to get mounted filesystems. Default: #{DEFAULT[:mount_cmd]}
  :skip_fs_regex: Regex used for filesystems to skip. Default: #{DEFAULT[:skip_fs_regex]}
  :warning_limit: Backup age limit to set status to WARNING (in seconds). Default: #{DEFAULT[:warning_limit]}
  :critical_limit: Backup age limit to set status to CRITICAL (in seconds). Default: #{DEFAULT[:critical_limit]}

== Objects format

  volume:
    :warning_limit: Backup age limit to set status to WARNING (in seconds).
    :critical_limit: Backup age limit to set status to CRITICAL (in seconds).
    :name: name to look for in log dir. In filesystems we change / for _ (/var -> _var, / -> _) but we can override this whoth the :name options 

If we only specify the volume, just skip that volume from checks

Example:

dom0_opt:
dom0_var:
  :warning_limit: 172800
  :critical_limit: 172800
/:
  :name: root

]    
  end
end

end # module Rasca
