module Rasca

# Checks Git repositories
# - Checks if we have changes in the repo (untracked files and added/deleted files
# - Acts depending on the proactivity level defined:
#   - :init : If repo is not a valid git repo, initialize it and do initial commit
#   - :commit : Automatically commit modified files, but does NOT commit file additions nor deletions
#   - :backup : Commit everything. Basically does "git rm --cached . && git add .". You can still exclude files in .gitignore
# - If parameter git_backup_url is defined
#   - Checks that remote is defined inside repo (git remote show). If its not, define it
#   - Push changes to defined url
class CheckGit < Check
  def initialize(*args)
    super

    # Initialize config variables
    #@variable1=@config_values.has_key?(:variable1) ? @config_values[:variable1] : "Default for variable1"

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
    @objects.keys.each do |dir|
      puts "Checking local repo: "+dir if @debug

      # If proactive was set from command line, set to :backup
      if proactive
        proactive=:backup
      else
        proactive=@objects[dir].has_key?(:proactive) ? @objects[dir][:proactive] : :none
      end

      puts "Proactive: "+proactive.to_s if @debug

      output=`cd #{dir} && git status 2>&1`

      # If proactive is NOT :backup, check changes
      if output =~ /^nothing to commit \(working directory clean\)$/
        puts "OK: no changes on "+dir if @debug
        incstatus("OK")
      elsif output =~ /Not a git repository/
        puts "Not a Git repo: "+dir if @debug
        if proactive == :init or proactive == :commit or proactive == :backup
          if system("cd #{dir} && git init && git add . && git commit -a -m 'GitChk Initial Commit' >/dev/null 2>&1")
            incstatus("CORRECTED")
            @short+="Initialized repo #{dir}, "
            @long+="#{dir} initialised as a GIT repository\n"
          else
            incstatus("WARNING")
            @short+="Couldn't init repo #{dir},"
            @long+="#{dir} is not a GIT repository, and it could not be initialized\n"
          end
        else
          incstatus("WARNING")
          @short+="No Git repo: #{dir}, "
          @long+="#{dir} is not a Git repo. You need to run 'git init'\n"
        end
      elsif output =~ /modified:/
        if proactive == :commit or proactive == :backup
          commit(dir,:changed)
        else
          incstatus("WARNING")
          @short+="Files changed in #{dir}, "
          @long+="There are files modified to #{dir}\n"
        end
      elsif output =~ /deleted:/
        if proactive == :backup
          # We don't care about changes, just commit
          commit(dir,:all)
        else
          # Deleted files require documenting, no proactive actions
          puts "WARNING: files deleted in #{dir}" if @debug
          @short+="Files deleted #{dir},"
          @long+="There are files deleted in #{dir}"
          incstatus("WARNING")
        end
      elsif output =~ /Untracked files:/
        if proactive == :backup
          # We don't care about changes, just commit
          commit(dir,:all)
        else
          # Untracked files require documenting, no proactive actions
          puts "WARNING: files added to #{dir}" if @debug
          @short+="Files added #{dir},"
          @long+="There are files added to #{dir}"
          incstatus("WARNING")
        end
      else
        puts "Unknown output on #{dir}" if @debug
        @short+="Unknown status on #{dir},"
        @long+="Unknown status on directory #{dir}\n"
        incstatus("UNKNOWN")
      end

      # If git_backup_url if defined, push changes
      if @objects[dir].has_key?(:git_backup_url)
        # Check if URL is defined
        check_git_url(dir,@objects[dir][:git_backup_url])
        # Push
        if @debug
          cmd ="cd #{dir} && GIT_SSH=/root/bin/gitbackup.sh git push backup master 2>&1"
        else
          cmd ="cd #{dir} && GIT_SSH=/root/bin/gitbackup.sh git push backup master >/dev/null 2>&1"
        end
        unless system(cmd)
          @short+="Error pushing #{dir} to remote,"
          incstatus("WARNING")
        end
      end
    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="All repos up to date"
    end
  end

  # Checks if remote url is defined as "backup". If it's not, define it
  def check_git_url(dir,git_backup_url)
    puts "Checking if #{git_backup_url} is defined as remote 'backup'" if @debug

    if system("cd #{dir} && git remote -v | grep -q #{git_backup_url}")
      puts "GOOD #{git_backup_url} is defined as remote 'backup'" if @debug
    else
      puts "#{git_backup_url} is NOT defined as remote 'backup'. Adding it" if @debug
      if system("cd #{dir} && git remote add backup #{git_backup_url} >/dev/null 2>&1")
        @short+="Could not add remote backup url to repo #{dir},"
        incstatus("WARNING")
      end
    end
  end

  # Commit changes to repo
  # What to commit depends on "type" parameter:
  # :changed : commit only changed files
  # :added : commit changes and file additions
  # :all : commit all. changes, added files and deleted files
  def commit(dir,type=:changed)
    gitcmd = nil
    case type
      when :changed
        gitcmd = "git commit -a -m 'GitChk Automatic Commit'"
      when :added
        gitcmd = "git add . && git commit -a -m 'GitChk Automatic Commit'"
      when :all
        gitcmd = "git rm -r --cached . && git add . && git commit -a -m 'GitChk Automatic Commit'"
      else
        raise "Invalid type for commit"
    end
    if @debug
      cmd="(cd #{dir} && #{gitcmd}) 2>&1"
    else
      cmd="(cd #{dir} && #{gitcmd}) > /dev/null 2>&1"
    end
    if system(cmd)
      incstatus("CORRECTED")
      @short+="Commited changes to #{dir}, "
      @long+="#{dir} had changed files, commited\n"
    else
      incstatus("WARNING")
      @short+="Couldn't commit changes to #{dir}, "
      @long+="#{dir} had changes, and it could not be commited\n"
    end
  end

  def info
    %[
== Description

Checks repositories with Git.

== Parameters in config file

  :none: It doesn't use any additional parameter

== Objects format

  directory:
    :proactive: Level of proactivity. 

Valid proactive levels:
  :init -> Initialize if directory is not a Git repo
  :commit -> Commit changes (not added nor deleted files)

Example:

/etc:
  :proactive: :commit

]    
  end
end

end # module Rasca
