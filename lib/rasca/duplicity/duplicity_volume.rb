module Rasca

## Manage backups with Duplicity
class DuplicityVolume

  # Debug and testing
  attr_accessor :debug, :testing
  # Volume name. By default the path is used, subsituting "/" with "_"
  attr_accessor :name
  # Path to the duplicity binary
  attr_accessor :duplicity
  # Duplicity archive dir
  attr_accessor :archivedir
  # Duplicity temporary dir
  attr_accessor :tempdir
  # ssh key file if we use sftp for backup destination URL
  attr_accessor :sshkeyfile
  # Time between full backups. Default 6D
  attr_accessor :timetofull
  # GPG encryption key and password
  attr_accessor :encryptkey, :encryptkeypass 
  # Volume size to use for storing remote backup files
  attr_accessor :volsize
  # Volume path. Used if we use a simbolic name
  attr_accessor :path
  # Whether to keep in one filesystem or include mounted filesystems
  attr_accessor :onefilesystem
  # Base destination URL for backup
  attr_accessor :baseurl
  # Where to store lastbackup information
  attr_accessor :backup_log_dir
  # How many full backups to keep when we run a "remove_old" command
  attr_accessor :keepfull
  # Target directory for "restore"
  attr_accessor :restore_dir
  # File (or directory) to restore. Relative to the backup root
  attr_accessor :file_to_restore

  # Information about last backup and las full backup
  attr_reader :last_backup, :last_full
 
  ## Initialize the volume attributes based on global config and configured attributes
  def initialize(volume,config,options)

    # Combine configs
    if options.is_a? Hash
      config_values=config.merge(options) unless options.nil?
    else
      config_values=config
    end

    # Initialize config variables with given parameters or defaults
    @name=config_values.has_key?(:name) ? config_values[:name] : volume.gsub("/","_")
    @duplicity=config_values.has_key?(:duplicity) ? config_values[:duplicity] : "/usr/bin/duplicity"
    @archivedir=config_values.has_key?(:archivedir) ? config_values[:archivedir] : ""
    @tempdir=config_values.has_key?(:tempdir) ? config_values[:tempdir] : "/var/tmp"
    @sshkeyfile=config_values.has_key?(:sshkeyfile) ? config_values[:sshkeyfile] : ""
    @timetofull=config_values.has_key?(:timetofull) ? config_values[:timetofull] : "20D"
    @keepfull=config_values.has_key?(:keepfull) ? config_values[:keepfull] : "3"
    @encryptkey=config_values.has_key?(:encryptkey) ? config_values[:encryptkey] : ""
    @encryptkeypass=config_values.has_key?(:encryptkeypass) ? config_values[:encryptkeypass] : ""
    @volsize=config_values.has_key?(:volsize) ? config_values[:volsize] : "25"
    @path=config_values.has_key?(:path) ? config_values[:path] : volume
    @onefilesystem=config_values.has_key?(:onefilesystem) ? config_values[:onefilesystem] : true
    @include=config_values.has_key?(:include) ? config_values[:include] : []
    @exclude=config_values.has_key?(:exclude) ? config_values[:exclude] : []
    @baseurl=config_values.has_key?(:baseurl) ? config_values[:baseurl] : "/dat/bck"
    @backup_log_dir=config_values.has_key?(:backup_log_dir) ? config_values[:backup_log_dir] : "/var/lib/modularit/data/lastbackups"
    @restore_dir=config_values.has_key?(:restore_dir) ? config_values[:restore_dir] : "/var/tmp/rasca_restore"
    @file_to_restore=config_values.has_key?(:file_to_restore) ? config_values[:file_to_restore] : nil

    # Check if we should use LVM snapshots
    @use_lvm_snapshot=false
    if config_values.has_key?(:use_lvm_snapshot)
      # Initialize options for LVM snapshots
      @use_lvm_snapshot=true
      snapshot_options=config_values[:use_lvm_snapshot]
      @lvcreate=snapshot_options.has_key?(:lvcreate) ? snapshot_options[:lvcreate] : "/usr/sbin/lvcreate" 
      @lvremove=snapshot_options.has_key?(:lvremove) ? snapshot_options[:lvremove] : "/usr/sbin/lvremove" 
      @fs_freeze=snapshot_options.has_key?(:fs_freeze) ? snapshot_options[:fs_freeze] : "" 
      @fs_unfreeze=snapshot_options.has_key?(:fs_unfreeze) ? snapshot_options[:fs_unfreeze] : "" 
      @mount_cmd=snapshot_options.has_key?(:mount_cmd) ? snapshot_options[:mount_cmd] : "/bin/mount" 
      @snapshot_size=snapshot_options.has_key?(:snapshot_size) ? snapshot_options[:snapshot_size] : "/bin/mount" 
      # Check mandatory options
      if snapshot_options.has_key?(:lv) and snapshot_options.has_key?(:vg) and snapshot_options.has_key?(:mountpoint)
        @lv=snapshot_options[:lv]
        @vg=snapshot_options[:vg]
        @mountpoint=snapshot_options[:mountpoint]
        # Since we are going to mount the snapshot under :mountpoint, we need to backup :mountpoint
        @path=@mountpoint
      else
        raise "ERROR: snapshot backup requested for #{@name} but not all mandatory options are configured (:lv,:vg,:mountpoint)"
      end 
    end
    
  end

  ## Run backup 
  def run(command)

    # If creating backup and using snapshot, create and mount snapshot
    if (command=="inc" or command=="full") and @use_lvm_snapshot==true
      # Freeze filesystem if needed
      unless @fs_freeze.empty? or @fs_unfreeze.empty?
        puts "Freezing filesystem: #{@fs_freeze}" if @debug
        system(@fs_freeze) unless @testing
      end
      # Create snapshot
      cmd="#{@lvcreate} --snapshot -L#{@snapshot_size} -n snap-#{@lv} /dev/#{@vg}/#{@lv}"
      puts "Creating snapshot: #{cmd}" if @debug
      system(cmd) unless @testing
      # Unfreeze filesystem
      unless @fs_unfreeze.empty?
        puts "Unfreezing filesystem: #{@fs_unfreeze}" if @debug
        system(@fs_unfreeze) unless @testing
      end
      # Mount command
      cmd="#{@mount_cmd} /dev/#{@vg}/snap-#{@lv} #{@mountpoint}"
      puts "Mounting snapshot: #{cmd}" if @debug
      system(cmd) unless @testing
    end

    # Duplicity backup command
    cmd=gencmd(command)
    puts "Running: #{cmd}" if @debug
    @output=""
    unless @testing
      unless @testing
        IO.popen(cmd) do |f|
          until f.eof?
            line=f.gets
            puts line if @debug or command=="list" or command=="col"
            @output+=line 
          end
        end
      end
      retcode=$?.exitstatus
      # Error running binary
      if retcode == 127
        puts "ERROR running binary. Is duplicity installed in #{@duplicity}?"
      # Correct execution
      elsif retcode == 0
        if (command=="inc" or command=="full")
          stats=Hash.new
          # Parse duplicity output
          stats=parseOutput(@output)
          puts YAML.dump(stats) if @debug
          # Check statistics
          retcode=128 if stats[:sourcefiles] <= 1
          # FIXME: Check all statistics also with history data
          # Save statistics to persistent data
          # FIXME: WE NEED TO INITIALIZE PERSISTENT DATA. See the Check base class
          #if @persist.has_key?(@name)
          #  @persist[@name].push(stats)
          #else
          #  @persist[@name]=[stats]
          #end

          ## Write timestamp for CheckBackups
          FileUtils.mkdir_p @backup_log_dir unless File.directory? @backup_log_dir
          FileUtils.touch("#{@backup_log_dir}/#{name}")
        elsif command=="col"
          chain=parse_collection_output(@output)
          if chain.instance_of? Hash
            @last_full=chain[:starttime]
            @last_backup=chain[:endtime]
          end
        end
      end
    end
    # If creating backup and using snapshot, umount and delete snapshot
    if (command=="inc" or command=="full") and @use_lvm_snapshot==true
      # Unmount command
      cmd="/bin/umount #{@mountpoint}"
      puts "Unmounting snapshot: #{cmd}" if @debug
      system(cmd) unless @testing
      # Delete snapshot
      cmd="#{@lvremove} -f /dev/#{@vg}/snap-#{@lv}"
      puts "Deleting snapshot: #{cmd}" if @debug
      system(cmd) unless @testing
    end

    # Return retcode
    retcode
  end
  ## Generate Backup cmd
  def gencmd(command)
    # Additional options
    opt_string="--tempdir #{@tempdir}" unless @tempdir.empty?
    opt_string+=" --archive-dir #{@archivedir}" unless @archivedir.empty?
    opt_string+=" --ssh-options=-oIdentityFile=#{@sshkeyfile}" unless @sshkeyfile.empty?
    opt_string+=" --full-if-older-than #{@timetofull}"
    if @encryptkey.empty?
      opt_string+=" --no-encryption"
    else
      opt_string+=" --encrypt-key #{@encryptkey}"
    end
    opt_string+=" --volsize #{@volsize}"
    # Add --include if any
    @include.each do |glob|
      opt_string+=" --include '#{glob}'" 
    end
    opt_string+=" --exclude-other-filesystems" if @onefilesystem
    opt_string+=" --exclude-if-present .exclude_from_backups"
    # Add --exclude if any
    @exclude.each do |glob|
      opt_string+=" --exclude '#{glob}'" 
    end
    opt_string+=" --name #{@name}"
    opt_string+=" -v5" if @debug

    case
      when (command=="inc" or command=="full")
        "#{@duplicity} #{command} #{opt_string} #{@path} #{@baseurl}/#{@name}"
      when (["col","collection","list"].include? command)
        "#{@duplicity} #{command} #{opt_string} #{@baseurl}/#{@name}"
      when (command=="remove_old")
        "#{@duplicity} remove-all-but-n-full #{@keepfull} --force #{opt_string} #{@baseurl}/#{@name}"
      when (command=="cleanup")
        "#{@duplicity} cleanup --extra-clean --force #{opt_string} #{@baseurl}/#{@name}"
      when (command=="restore")
        puts "Restoring files to #{@restore_dir}"
        opt_string+=" --file-to-restore #{@file_to_restore}" if @file_to_restore
        "#{@duplicity} #{command} #{opt_string} #{@baseurl}/#{@name} #{@restore_dir}"
      else
        ""
    end
  end
  ## Parse Duplicity Output (Backup statistics)
  def parseOutput(output)
    stats=Hash.new
    # Flag to mark if we are un statistics se
    output.each_line do |line|
      puts "LINE: #{line}" if @debug
      entry=line.split
      stats[:starttime]=entry[1].to_f if entry[0] == "StartTime" 
      stats[:endtime]=entry[1].to_f if entry[0] == "EndTime" 
      stats[:elapsedtime]=entry[1].to_f if entry[0] == "ElapsedTime" 
      stats[:sourcefiles]=entry[1].to_i if entry[0] == "SourceFiles" 
      stats[:sourcefilesize]=entry[1].to_f if entry[0] == "SourceFileSize" 
      stats[:newfiles]=entry[1].to_i if entry[0] == "NewFiles" 
      stats[:newfilesize]=entry[1].to_f if entry[0] == "NewFileSize" 
      stats[:deletedfiles]=entry[1].to_i if entry[0] == "DeletedFiles" 
      stats[:changedfiles]=entry[1].to_i if entry[0] == "ChangedFiles" 
      stats[:changedfilesize]=entry[1].to_f if entry[0] == "ChangedFileSize" 
      stats[:changeddeltasize]=entry[1].to_f if entry[0] == "ChangedDeltaSize" 
      stats[:deltaentries]=entry[1].to_i if entry[0] == "DeltaEntries" 
      stats[:rawdeltasize]=entry[1].to_f if entry[0] == "RawDeltaSize" 
      stats[:totaldestinationsizechange]=entry[1].to_f if entry[0] == "TotalDestinationSizeChange" 
      stats[:errors]=entry[1].to_i if entry[0] == "Errors" 
    end
    puts YAML.dump(stats) if @debug
    stats
  end
  ## Parse Duplicity Collection Output
  def parse_collection_output(output)
    chain=nil
    primary=false
    backup_set=false
    output.each_line do |line|
      # Check for primary chain
      primary=true if line.match /^Found primary backup chain/
      # Skip lines until we get to the primary chain
      next unless primary
      # Ok, we have a primary chain, create Hash if necessary
      chain={} unless chain.instance_of? Hash
      entry=line.split(": ")
      chain[:starttime]=duplicity_time(entry[1]) if entry[0].match /^Chain start time/
      chain[:endtime]=duplicity_time(entry[1]) if entry[0].match /^Chain end time/ 
      chain[:backup_sets]=entry[1].to_i if entry[0].match /^Number of contained backup sets/
      chain[:volumes]=entry[1].to_i if entry[0].match /^Total number of contained volumes/
      if line.match /Full|Incremental/
        # Ok, we have a set, create Hash if necessary
        chain[:sets]={} unless chain[:sets].instance_of? Hash
        entry=line.split(/\s{3,}/)
        type=entry[1].strip
        volumes=entry[3].to_i
        # Convert tstamp to Time object
        tstamp=duplicity_time(entry[2].strip)
        chain[:sets][tstamp]={:type=>type,:tstamp=>tstamp,:volumes=>volumes}
      end
    end 
    chain
  end
  ## Create a Time object from a Duplicity info timestamp
  # FIXME: There is probably a shorter and more eleganto way to do it
  def duplicity_time(string)
    # Split timestamp for mktime
    s=string.split(/\s+/)
    y=s[4]
    m=s[1]
    d=s[2]
    t=s[3].split(":")
    h=t[0]
    min=t[1]
    s=t[2]
    tstamp=Time.mktime(y,m,d,h,min,s)
  end
end

end # module Rasca
