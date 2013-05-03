module Rasca

# A Simple Template
class CheckBackup < Check

  DEFAULT={
    :log_dir => "/var/lib/modularit/data/lastbackups",
    :default_expiration => 4*24*60*60,
    :fs_types_cmd => "/usr/bin/grep -v nodev /proc/filesystems",
    :lvscan_cmd => "lvscan | grep -v swap | grep -v snap_",
    :mount_cmd => "mount",
    :skip_fs_regex => "iso9660|fuseblk"
  }

  attr_accessor :testing1, :testing2, :log_dir, :backup_skip_all,  :default_expiration, :fs_types_cmd, :lvscan_cmd, :mount_cmd, :skip_fs_regex

  def initialize(*args)
    super

    # Initialize config variables
    @log_dir=@config_values.has_key?(:log_dir) ? @config_values[:log_dir] : DEFAULT[:log_dir]
    @default_expiration=@config_values.has_key?(:default_expiration) ? @config_values[:default_expiration] : DEFAULT[:default_expiration]
    @backup_skip_all=@config_values.has_key?(:backup_skip_all) ? @config_values[:backup_skip_all] : nil
    @fs_types_cmd=@config_values.has_key?(:fs_types_cmd) ? @config_values[:fs_types_cmd] : DEFAULT[:fs_types_cmd]
    @lvscan_cmd=@config_values.has_key?(:lvscan_cmd) ? @config_values[:lvscan_cmd] : DEFAULT[:lvscan_cmd]
    @mount_cmd=@config_values.has_key?(:mount_cmd) ? @config_values[:mount_cmd] : DEFAULT[:mount_cmd]
    @skip_fs_regex=@config_values.has_key?(:skip_fs_regex) ? @config_values[:skip_fs_regex] : DEFAULT[:skip_fs_regex]

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
    entries=get_mounts_to_backup(entries)
    entries=get_lvs_to_backup(entries)
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
        if File.exists? "#{@log_dir}/#{file}"
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
    puts "ENTRY: #{entry}"
    dev=entry[:dev]
    mount=entry[:mount]
    expiration=@default_expiration
    name=nil
    puts "Checking backups for dev:#{dev} mount:#{mount} name:#{name}" if @debug
    object=get_object(entry)
    if object
      puts "Found object: #{object}" if @debug
      # Ok, we have an entry, If entry is a hash, read parameters
      if object.instance_of?Hash 
        expiration=object[:expiration] if object.has_key? :expiration
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
        puts "mtime : "+mtime.to_s if @debug
        if (Time.now - mtime) > expiration
          puts "OLD backup of #{dev}" if @debug
          @short+="OLD bcklog for #{dev},"
          @long+="Backup of #{dev} is too old"
          incstatus("WARNING")
        else
          found=true
          incstatus("OK")
        end
      else
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

TODO: We should integrate CheckDuplicity into this alarm

- Buscar el volumen (completo) en el objects
- Buscar el fichero con el nombre "traducido"
- OJO: en el antiguo BackupChk solo se especificaba el lv, sin VG (dom0_var en lugar de /dev/sys/dom0_var)
- Si no lo tiene, bucarlo por el nombre devmapper
- Si no lo tiene, buscarlo por el mount (a partir del nombre mapper)
Arreglar:
- Aplicar la traduccion a mapper solo a la salida de lvscan
- Cuando buscamos un entry, hay que indicar si es un alias o no, para que no se nos dupliquen los avisos de que no hay backup de algo con su nombre "normal", traducido a mapper y el directorio donde esta montado

== Parameters in config file

  :log_dir: Directory for backup timestamps. Default: #{DEFAULT[:log_dir]}
  :default_expiration: Default expiration limit in seconds. Default: #{DEFAULT[:default_expiration]}
  :skip_all: Skip all backup checks and set status OK and return the message specified by this option.
  :fs_types_cmd: Command to get filesystem types to backup. Default: #{DEFAULT[:fs_types_cmd]}
  :lvscan_cmd: Command to get LV list. Default: #{DEFAULT[:lvscan_cmd]}
  :mount_cmd: Command to get mounted filesystems. Default: #{DEFAULT[:mount_cmd]}
  :skip_fs_regex: Regex used for filesystems to skip. Default: #{DEFAULT[:skip_fs_regex]}

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
