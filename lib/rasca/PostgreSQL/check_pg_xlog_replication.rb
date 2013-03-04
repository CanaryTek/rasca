module Rasca

# A Simple Template
class CheckPgXlogReplication < Check
  def initialize(*args)
    super

    # Initialize config variables
    @psql=@config_values.has_key?(:psql) ? @config_values[:psql] : "/usr/bin/psql"
    @slave_cmd=@config_values.has_key?(:slave_cmd) ? @config_values[:slave_cmd] : "ps ax | grep postgres | grep waiting | grep -v grep"

    # More initialization
    #
  end
  # The REAL Check
  def check
    readObjects(@name)

    @objects.each do |cluster,opts|
      
      puts "Testing cluster: #{cluster}" if @debug

      # Check if I_am_master
      if opts.has_key?(:I_am_master) and opts[:I_am_master]
        incstatus("OK")
        @short="I_am_master for #{cluster}"
        @long+="I am configured as the master replica for cluster #{cluster}\n"
        next
      end

      # Read Cluster parameters
      if opts.has_key?(:master)
        @master=opts[:master] 
      else
        puts "ERROR: You have to set the :master parameter for cluster #{cluster}. SKIPPING"
        next
      end
      # Optional parameters
      @warning_delay=opts.has_key?(:warning_delay) ? opts[:warning_delay] : 5
      @critical_delay=opts.has_key?(:critical_delay) ? opts[:critical_delay] : 10
      @psql=opts[:psql] if opts.has_key?(:psql)
      @slave_cmd=opts[:slave_cmd] if opts.has_key?(:slave_cmd)
      
      if @testing
        # Use testing input (for unit testing)
      else
        # Use REAL input
      end
    
      ## CHECK CODE 
      master_xlog=getMasterXlog(opts[:master])
      slave_xlog=getSlaveXlog

      diff=master_xlog.to_i(16)-slave_xlog.to_i(16)
      puts "m:#{master_xlog} s:#{slave_xlog} diff: #{diff}" if @debug

      puts "critical_delay: #{@critical_delay} warning_delay: #{@warning_delay}" if @debug
      if master_xlog.empty? or slave_xlog.empty?
        incstatus("CRITICAL") 
        @short="#{cluster} invalid output for xlog (m:#{master_xlog} s:#{slave_xlog})"
        @long+="Invalid output for xlog in #{cluster}\n"
        @long+="  master xlog: #{master_xlog} \n"
        @long+="  slave xlog: #{slave_xlog} \n"
      elsif slave_xlog.to_i(16) > master_xlog.to_i(16)
        incstatus("CRITICAL") 
        @short="#{cluster} master is behind slave??? (m:#{master_xlog} s:#{slave_xlog})"
        @long+="Master server in cluster #{cluster} is behind slave!!!???\n"
        @long+="  master xlog: #{master_xlog} \n"
        @long+="  slave xlog: #{slave_xlog} \n"
      elsif diff < @warning_delay
        incstatus("OK")
        @short+="#{cluster} in sync (m:#{master_xlog} s:#{slave_xlog}), "
        @long+="Slave server n cluster #{cluster} in sync with master\n"
        @long+="  master xlog: #{master_xlog} \n"
        @long+="  slave xlog: #{slave_xlog} \n"
      elsif @warning_delay <= diff and diff < @critical_delay
        incstatus("WARNING") 
        @short="#{cluster} slave NOT in sync (m:#{master_xlog} s:#{slave_xlog})"
        @long+="Slave server in cluster #{cluster} out of sync with master\n"
        @long+="  master xlog: #{master_xlog} \n"
        @long+="  slave xlog: #{slave_xlog} \n"
      elsif master_xlog.to_i(16) >= @critical_delay
        incstatus("CRITICAL") 
        @short="#{cluster} slave NOT in sync (m:#{master_xlog} s:#{slave_xlog})"
        @long+="Slave server in cluster #{cluster} out of sync with master\n"
        @long+="  master xlog: #{master_xlog} \n"
        @long+="  slave xlog: #{slave_xlog} \n"
      else
        incstatus("CRITICAL")
        @short+="#{cluster} UNKNOWN??? (m:#{master_xlog} s:#{slave_xlog}), "
        @long+="Cluster #{cluster} unknown difference\n"
        @long+="  master xlog: #{master_xlog} \n"
        @long+="  slave xlog: #{slave_xlog} \n"
      end
      puts "#{@status}: #{@short}" if @debug
    end
  end
  # Returns the xlog file that the master is using
  def getMasterXlog(master)
    xlog_file=""
    output=""
    if @testing
      # Use testing input (for unit testing)
      output=File.open("#{@testing}/master_out.txt").readlines
    else
      # Use REAL input
      # cmd: psql -h bbdd -c"select pg_xlogfile_name(pg_current_xlog_location());" postgres
      cmd="#{@psql} -h #{@master} -c'select pg_xlogfile_name(pg_current_xlog_location());' postgres"
      puts "Running: #{cmd}" if @debug
      output=%x[#{cmd}]
      puts output if @debug
      retcode=$?.exitstatus
      if retcode != 0
        puts "ERROR running command" if @debug
      else
        output=output.split("\n")
      end
    end
    # Parse output
    if output.is_a?(Array) and output[2].is_a?(String)
      xlog_file=output[2].strip
    end
    puts "xlog in master: |#{xlog_file}|" if @debug
    xlog_file
  end
  # Returns the xlog file that the slave is waiting for
  def getSlaveXlog
    xlog_file=""
    output=""
    if @testing
      # Use testing input (for unit testing)
      output=File.open("#{@testing}/slave_out.txt").readlines
    else
      # Use REAL input
      # cmd: ps ax | grep postgres | grep waiting
      cmd=@slave_cmd
      puts "Running: #{cmd}" if @debug
      output=%x[#{cmd}]
      puts output if @debug
      retcode=$?.exitstatus
      if retcode != 0
        puts "ERROR running command" if @debug
      else
        output=output.split("\n")
      end
    end
    # Parse output
    if output.is_a?(Array) and output[0].is_a?(String)
      xlog_file=output[0].split.last.strip
    end
    puts "xlog in slave: |#{xlog_file}|" if @debug
    xlog_file
  end
  # Info
  def info
    %[
== Description

Checks the status of PostgreSQL xlog based replication in the slave

It checks the xlog file that the master is using (select pg_xlogfile_name(pg_current_xlog_location())
and compares it with the one that the slave is waiting

It needs to connect to master server using psql, so you may need to add authentication options (user, pass, etc) to the
:pgsql: configuration option

== Parameters in config file

  :psql: Full path of pgsql binary. It can also be used to add options (user, pass, etc). DEFAULT: /usr/bin/pgsql
  :slave_cmd: Comand to get the xlog that the slave is waiting. DEFAULT: ps ax | grep postgres | grep waiting | grep -v grep

== Objects format

  cluster:
    :psql: You can override the default pgsql command for this cluster
    :slave_cmd: You can override the default slave_cmd command for this cluster
    :master: Cluster master host
    :warning_delay: If slave is this number of xlog files behind master, set status=WARNING. DEFAULT: 5
    :critical_delay: If slave is this number of xlog files behind master, set status=CRITICAL. DEFAULT: 10
    :I_am_master: (true/false) Tells if this is a master replica, si it doesn't have to check replication. Default: false

Example:

mydatabase:
  :master: mydatabase.mycompany.com
  :warning_delay: 10
  :critical_delay: 15

]    
  end
end

end # module Rasca
