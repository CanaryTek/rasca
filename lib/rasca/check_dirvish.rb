module Rasca

# FIXME:
# Maybe it would be better to have an array of images (objects) and each object could be checked

# Vault Class
class DirvishVault
  attr_accessor :bank, :name, :debug
  attr_reader :lastImage

  def initialize(bank,name)
    @bank=bank
    @name=name
    @path=bank+"/"+name

    # Read last image
    @lastImage=getLastImage

  end

  # getLastImage
  def getLastImage
    lastImage=nil
    lastImage=File.basename(Dir[@path+"/2*"].sort.last.to_s)
  end

  # Checks if last backup has an rsync_error
  def rsyncError?
    File.exists? @path+"/"+"/"+@lastImage+"/rsync_error"
  end

  # Checks if last backup is empty
  # We consider empty a vault that has no files (it may have several directories)
  def isEmpty?(empty_max_level=10)
    files=Array.new
    empty=true
    # Recursivity level control
    base_dir=@path+"/"+"/"+@lastImage+"/tree"
    files=Dir[base_dir+"/*"]
    files.each do |entry|
      if File.directory? entry
        if entry.sub("#{base_dir}/","").split("/").size < empty_max_level
          files.concat(Dir[entry+"/*"])
        end
      else
        empty=false
        break
      end
    end
    empty
  end

  # Update the last_known_good symlink pointing to the last valid backup
  def updateLastKnownGood
    tstamp=lastImage
    if ! File.exist? "#{@path}/last_known_good" or File.readlink("#{@path}/last_known_good") != "#{@path}/#{tstamp}"
      puts "Updating last_known_link -> #{tstamp}" if @debug
      begin
        puts "deleting #{@path}/last_known_good" if @debug
        File.unlink("#{@path}/last_known_good")
      rescue
      end
      File.symlink("#{tstamp}","#{@path}/last_known_good")
    end
  end
 
  # Checks if last backup is older than "age" days
  def isOlder?(age)
    puts "Checking image age: "+age+" > "+@lastImage+"?" if @debug
    age.to_i > @lastImage.to_i
  end

end

# A Simple Template
class CheckDirvish < Check
  def initialize(*args)
    super

    ## Initialize config variables
    @dirvish_master=@config_values.has_key?(:dirvish_master) ? @config_values[:dirvish_master] : "/etc/dirvish/master.conf"
    # Default recursivity level to check for empty vaults
    @default_empty_level=@config_values.has_key?(:default_empty_level) ? @config_values[:default_empty_level] : 10
    # Default check status when backups fail (can be overriden per vault in object file)
    @default_failed_status=@config_values.has_key?(:default_failed_status) ? @config_values[:default_failed_statud] : "WARNING"

    # More initialization
    #
  end
  # The REAL Check
  def check
    @objects=readObjects(@name)
    
    if @testing
      # Use testing input (for unit testing)
    else
      # Use REAL input
    end

    ## CHECK CODE 
    readBanks(@dirvish_master).each do |bank|
      # Check Vaults in bank
      checkVaults(bank)
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end
  # return the configured banks
  def readBanks(config="/etc/dirvish/master.conf")
    banks=Array.new()
    bankfound=false

    File.open(config).each do |line|
      line.chomp!
      if line =~ /^bank:/
        bankfound=true
        next
      end
      next if (!bankfound)
      break if line =~ /^\s*$|^#/
      line.strip!
      banks.push(line)
      puts "bank: |"+line+"|" if @debug
    end
    banks 
  end
  # Check vaults in given bank
  def checkVaults(bank)
    vaults=findVaults(bank)
    incstatus("CRITICAL") if vaults.empty?
    vaults.each do |name|
      # Default expiration
      expiration=@default_expiration
      # Default failed status
      failed_status=@default_failed_status

      vault=DirvishVault.new(bank,name)
      vault.debug=@debug
      puts " Checking vault: "+vault.name+" lastimage: "+vault.lastImage if @verbose
      # FIXME: Check vault forced status
      if @objects.has_key? vault.name
        expiration=@objects[vault.name][:expiration] if @objects[vault.name].has_key? :expiration
	puts "  expiration for #{vault.name} is #{expiration}" if @debug
        failed_status=@objects[vault.name][:failed_status] if @objects[vault.name].has_key? :failed_status
	puts "  failed_status for #{vault.name} is #{failed_status}" if @debug
      end
      # Calculate timestamp to compare (expiration is un hours so *3600 sec/hour)
      tstamp=Time.now-3600*expiration.to_i
      puts "tstamp #{vault.name}: "+tstamp.strftime("%Y%m%d") if @debug
      if vault.isOlder?(tstamp.strftime("%Y%m%d"))
        @short+="#{vault.name} OLD, "
        @long+="#{vault.name} is too OLD\n"
        incstatus(failed_status)
      elsif vault.rsyncError?
        @short+="#{vault.name} rsync ERROR, "
        @long+="#{vault.name} rsync ERROR\n"
        incstatus(failed_status)
      elsif vault.isEmpty?(@default_empty_level)
        @short+="#{vault.name} EMPTY, "
        @long+="#{vault.name} rsync EMPTY\n"
        incstatus(failed_status)
      else
        # OK, update last_known_good symlink
        vault.updateLastKnownGood
        incstatus("OK")
      end
    end
  end
  # Find vaults in a given bank
  def findVaults(bank)
    vaults=Array.new
    Dir["#{bank}/*"].each do |dir|
      puts "Checking dir: "+dir if @debug
      next unless File.directory? dir+"/dirvish"
      puts "Vault: "+dir if @debug
      vaults.push(File.basename(dir))
    end
    vaults
  end
  # return vaults in runall
  def vaultsInRunAll
    false
  end
  def info
    %[
== Description

Checks dirvish backups to make sure we have up to date backups:

- Look for dirvish vaults in every bank (directories with a "dirvish" directory inside)
- Check that we see all vaults configured in run-all
- Check that all the vaults we see are in run-all. FIXME: This may not be needed, we check freshness
- Check that we have an entry for this vault in default.hist
- Check if we have a rsync_error directory
- Check last good backup is not older than limit for that vault
- Check that vault is not empty
TODO:
- Get stats from log and
  - Check the deviation from the average is not aver limit

== Parameters in config file

  :dirvish_master: Dirvish master file location (default: /etc/dirvish/master.conf)
  :default_empty_level: Consider vault empty if we descend to this level without finding any file (default: 10)
  :default_failed_status: Status of alert if any backup failed. Default: WARNING
  :default_expiration: Consider failed backup if last good backup is older than this (hours). Default: 36

== Objects format

  vault:
    :failed_status: status to set if this backup failed. Default: default_failed_status
    :expiration: expiration time in hours. Only consider failed if last vail backup is older than this. Default: default_expiration

Example:

critical_backup:
  :failed_status: CRITICAL
  :expiration: 12

]    
  end
end

end # module Rasca
