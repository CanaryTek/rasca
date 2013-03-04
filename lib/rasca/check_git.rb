module Rasca

# A Simple Template
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

      # Se proactivity
      proactive=@objects[dir].has_key?(:proactive) ? @objects[dir][:proactive] : :none

      puts "Proactive: "+proactive.to_s if @debug

      output=`cd #{dir} && git status 2>&1`

      if output =~ /^nothing to commit \(working directory clean\)$/
        puts "OK: no changes on "+dir if @debug
        incstatus("OK")
      elsif output =~ /Not a git repository/
        puts "Not a Git repo: "+dir if @debug
        if proactive == :init or proactive == :commit
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
        if proactive == :commit
          if system("cd #{dir} && git commit -a -m 'GitChk Automatic Commit' >/dev/null 2>&1")
            incstatus("CORRECTED")
            @short+="Commited changes to #{dir}, "
            @long+="#{dir} had changed files, commited\n"
          else
            incstatus("WARNING")
            @short+="Couldn't commit changes to #{dir}, "
            @long+="#{dir} had changed files, and it could not be commited\n"
          end
        else
          incstatus("WARNING")
          @short+="Files changed in #{dir}, "
          @long+="There are files modified to #{dir}\n"
        end
      elsif output =~ /deleted:/
        # Deleted files require documenting, no proactive actions
        puts "WARNING: files deleted in #{dir}" if @debug
        @short+="Files deleted #{dir},"
        @long+="There are files deleted in #{dir}"
        incstatus("WARNING")
      elsif output =~ /Untracked files:/
        # Untracked files require documenting, no proactive actions
        puts "WARNING: files added to #{dir}" if @debug
        @short+="Files added #{dir},"
        @long+="There are files added to #{dir}"
        incstatus("WARNING")
      else
        puts "Unknown output on #{dir}" if @debug
        @short+="Unknown status on #{dir},"
        @long+="Unknown status on directory #{dir}\n"
        incstatus("UNKNOWN")
      end

    end

    # Set Messages if OK and empty messages
    if status == "OK" and @short == ""
      @short="All repos up to date"
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
