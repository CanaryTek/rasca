module Rasca

## Manage backups with Duplicity
class DuplicityVolume

  attr_accessor :debug, :testing, :name, :duplicity, :archivedir, :sshkeyfile, :timetofull, :encryptkey, :encryptkeypass, 
                :volsize, :path, :onefilesystem, :baseurl
 
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

  end

  ## Run backup 
  def run(command)

    puts "Running command: #{command}" if @debug

    #vault,type,timetofull,encryptkey,volsize,path,baseurl,onefilesystem=true
    cmd=gencmd(command)
    puts "Running: #{cmd}" if @debug
    system(cmd) unless @testing
     
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
end

end # module Rasca
