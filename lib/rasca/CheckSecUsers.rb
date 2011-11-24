module Rasca

require 'etc'

# Does some simple security checks on users
class CheckSecUsers < Check
  def initialize(*args)
    super

    # More initialization
    #
  end
  # The REAL Check
  def check
    @objects=readObjects(@name)

    # Initial status -> OK
    # Load users info    
    basedir = @testing? @testing : "/etc"
    puts "Reading from: "+basedir if @debug
    users=load_pwent(basedir)

    # Check users
    users.keys.each do |user|
      puts "Testing |user| |pass|: |#{user}| |#{users[user][:passwd]}|" if @debug
      if users[user][:passwd] =~ /^\*$|^\!\!$/
        incstatus("OK")
        @long+="User #{user} locked. OK\n"
        next
      end
      puts YAML.dump(users[user]) if @debug
      if trivial_pass(user,users[user][:passwd])
        puts "Trivial pass found for: "+user if @debug
        @short+="#{user}: trivial passwd, "
        @long+="Passwd for #{user} TRIVIAL\n"
        incstatus("CRITICAL")
      elsif banned_pass(user,users[user][:passwd])
        puts "Banned pass found for: "+user if @debug
        @short+="#{user}: banned passwd, "
        @long+="Passwd for #{user} BANNED\n"
        incstatus("CRITICAL")
      else
        incstatus("OK")
        @long+="Passwd for #{user} OK\n"
      end
    end

    ## CHECK CODE 

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="Everything OK"
    end
  end
  # Check if user has a trivial pass
  def trivial_pass(user,pass)
    trivial=false
    passwd_to_check=[ user+".pass", user+"123", user]
    passwd_to_check.each do |p|
      puts "Testing: |#{pass}| |#{p}|" if @debug
      trivial = true if p.crypt(pass) == pass
    end
    trivial 
  end
  # Check if root has a banned pass
  def banned_pass(user,pass)
    banned=false
    passwd_to_check=@objects.has_key?(:banned_passwd) ? @objects[:banned_passwd] : []
    passwd_to_check.each do |p|
      puts "Testing: |#{pass}| |#{p}|" if @debug
      banned = true if p.crypt(pass) == pass
    end
    banned
  end
  # Load passwd and shadow in a user hash
  def load_pwent(dir)
    users=Hash.new

    # Load passwd
    File.open(dir+"/passwd").each do |line|
      line.chomp!
      entry=Array.new
      user=Hash.new
      entry=line.split(":")
      user[:name]=entry[0]
      user[:uid]=entry[2]
      user[:gid]=entry[3]
      user[:gcos]=entry[4]
      user[:home]=entry[5]
      user[:shell]=entry[6]
      users[user[:name]]=user
    end
    File.open(dir+"/shadow").each do |line|
      line.chomp!
      entry=Array.new
      user=Hash.new
      entry=line.split(":")
      if users.has_key?entry[0]
        # User found in hash, add passwd
        users[entry[0]][:passwd]=entry[1]
      end
    end
    puts YAML.dump(users) if @debug
    users
  end
  def info
    %[
== Description

Does some simple security checks on users:
  - Trivial passwords
  - Users with banned passwords

== Parameters in config file

  :none: It doesn't use any additional parameter

== Objects format

  banned_passwd: Array of banned root passwords. root should NOT have any of these passwords

Example:

:banned_passwd: [ "banned", "banned2" ]

]    
  end
end

end # module Rasca
