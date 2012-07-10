module Rasca

# A Simple Template
class CheckDuplicity < Check
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
    incstatus("OK") if vaults.empty?
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

Checks duplicity backups to make sure we have up to date backups:

- Check last good backup is not older than limit for that vault
- Check that vault is not empty

TODO:
- Get stats from log and
  - Check the deviation from the average is not aver limit

== Parameters in config file

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
