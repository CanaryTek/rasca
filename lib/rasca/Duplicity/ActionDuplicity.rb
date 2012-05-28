module Rasca

## Manage backups with Duplicity
class ActionDuplicity < Action

  attr_accessor :command
 
  def initialize(*args)
    super
    readObjects(@name)
    # More initialization
    #
  end
  ## Run backup for all vaults
  def runall(command)
    @objects.keys.each do |volume|
      run(volume,command)
    end 
  end
  ## Run backup for a given vault
  def run(volume,command)

    puts "Running volume: #{volume}" if @verbose

    if @objects.has_key?(volume)
      
      vol=DuplicityVolume.new(volume,@config_values,@objects[volume])
      vol.debug=@debug
      vol.testing=@testing
      vol.run(command)
    else
      puts "ERROR: Volume #{volume} is not defined"
      return false
    end 
     
  end
  #
  ## Print information
  def info
    %[
== Description

Checks that we have up to date backups with duplicity.

== Parameters in config file

  :duplicity: Duplicity binary. Default: /usr/bin/duplicity
  :sshkeyfile: SSH private key file for SSH URL. Default: none
  :timetofull: If last full backup is older than this, do a full backup. Default: 6D (Duplicity syntax)
  :encryptkey: ID of GPG key to use for encryption (see with gpg --list-keys)
  :encryptkeypass: Passphrase to access the PGP encryption key
  :volsize: Default volsize (Default 25)
  :baseurl: Duplicity base URL where to store backups. Will append the vault name

== Objects format

  path:
    :name: Vault Name
    :sshkeyfile: Override default value for this vault
    :timetofull: Override default value for this vault
    :encryptkey: Override default value for this vault
    :encryptkeypass: Override default value for this vault
    :volsize: Override default value for this vault
    :baseurl: We can override the baseurl for this volume
    :onefilesystem: [true|false] Specify if the backup should stay in same filesystem. Default: true

Example:

root:
  :path: /
  :volsize: 25
  :baseurl: file:///dat/bck

]    
  end
end

end # module Rasca
