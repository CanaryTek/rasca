module Rasca

## Manage backups with Duplicity
class DuplicityVolume

  attr_accessor :debug, :testing, :name, :duplicity, :archivedir, :sshkeyfile, :timetofull, :encryptkey, :encryptkeypass, 
                :volsize, :path, :onefilesystem, :baseurl, :backup_log_dir
 
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
    @sshkeyfile=config_values.has_key?(:sshkeyfile) ? config_values[:sshkeyfile] : ""
    @timetofull=config_values.has_key?(:timetofull) ? config_values[:timetofull] : "6D"
    @encryptkey=config_values.has_key?(:encryptkey) ? config_values[:encryptkey] : "Default encrypt key"
    @encryptkeypass=config_values.has_key?(:encryptkeypass) ? config_values[:encryptkeypass] : "Change this pass!!"
    @volsize=config_values.has_key?(:volsize) ? config_values[:volsize] : "25"
    @path=config_values.has_key?(:path) ? config_values[:path] : volume
    @onefilesystem=config_values.has_key?(:onefilesystem) ? config_values[:onefilesystem] : true
    @baseurl=config_values.has_key?(:baseurl) ? config_values[:baseurl] : "/dat/bck"
    @backup_log_dir=config_values.has_key?(:backup_log_dir) ? config_values[:backup_log_dir] : "/var/lib/modularit/data/lastbackups"

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
    unless @testing
      output=%x[#{cmd}] unless @testing
      puts output if @debug
      retcode=$?.exitstatus
      # Error running binary
      if retcode == 127
        puts "ERROR running binary. Is duplicity installed in #{@duplicity}?"
      # Correct execution
      elsif retcode == 0
        if (command=="inc" or command=="full")
          stats=Hash.new
          # Parse duplicity output
          stats=parseOutput(output)
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
    opt_string="--tempdir /var/tmp"

    # Additional options
    opt_string+=" --archive-dir #{@archivedir}" unless @archivedir.empty?
    opt_string+=" --ssh-options=-oIdentityFile=#{@sshkeyfile}" unless @sshkeyfile.empty?
    opt_string+=" --full-if-older-than #{@timetofull}"
    if @encryptkey.empty?
      opt_string+=" --no-encryption"
    else
      opt_string+=" --encrypt-key #{@encryptkey}"
    end
    opt_string+=" --volsize #{@volsize}"
    opt_string+=" --exclude-other-filesystems" if @onefilesystem
    opt_string+=" --name #{@name}"

    case
      when (command=="inc" or command=="full")
        "#{@duplicity} #{command} #{opt_string} #{@path} #{@baseurl}/#{@name}"
      when (command=="col" or command=="collection" or command=="list")
        "#{@duplicity} #{command} #{opt_string} #{@baseurl}/#{@name}"
      when (command=="restore")
        puts "Restoring files to /var/tmp/rascaRestore"
        "#{@duplicity} #{command} #{opt_string} #{@baseurl}/#{@name} /var/tmp/rascaRestore"
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
  def parseColOutput(output)
    history=Array.new
    puts YAML.dump(history) if @debug
    #stats
  end
end

end # module Rasca
