require "helper"
require "fileutils"

class TestDuplicityVolume < Test::Unit::TestCase

  context "Creating a volume with empty options" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"s3://s3-eu-west-1.amazonaws.com/backups-client",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options=nil

      @volume=Rasca::DuplicityVolume.new("/",@config_values,@options)
      @volume.testing=true
    end

    should 'not give an error' do
      assert_equal "6D",@volume.timetofull
    end
  end

  context "Creating the / (root) volume" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"s3://s3-eu-west-1.amazonaws.com/backups-client",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:name=>"root",:timetofull=>"15D",:volsize=>"25"}

      @volume=Rasca::DuplicityVolume.new("/",@config_values,@options)
      @volume.testing=true
    end

    should 'correctly populate :name' do
      assert_equal "root",@volume.name
    end
    should 'correctly populate :sshkeyfile' do
      assert_equal "/root/.ssh/id_dsa",@volume.sshkeyfile
    end
    should 'correctly populate :timetofull' do
      assert_equal "15D",@volume.timetofull
    end
    should 'correctly populate :encryptkey' do
      assert_equal "292599DD",@volume.encryptkey
    end
    should 'correctly populate :encryptkeypass' do
      assert_equal "TestPass",@volume.encryptkeypass
    end
    should 'correctly populate :volsize' do
      assert_equal "25",@volume.volsize
    end
    should 'correctly populate :path' do
      assert_equal "/",@volume.path
    end
    should 'correctly populate :baseurl' do
      assert_equal "s3://s3-eu-west-1.amazonaws.com/backups-client",@volume.baseurl
    end
    should 'correctly populate :onefilesystem' do
      assert_equal true,@volume.onefilesystem
    end
  end

  context "Creating the /var volume" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"s3://s3-eu-west-1.amazonaws.com/backups-client",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:sshkeyfile=>"/root/.ssh/backup.dsa",:encryptkey=>"29GHT",:encryptkeypass=>"MyPass",:onefilesystem=>false}

      @volume=Rasca::DuplicityVolume.new("/var",@config_values,@options)
      @volume.testing=true
    end

    should 'correctly populate :name' do
      assert_equal "_var",@volume.name
    end
    should 'correctly populate :sshkeyfile' do
      assert_equal "/root/.ssh/backup.dsa",@volume.sshkeyfile
    end
    should 'correctly populate :timetofull' do
      assert_equal "6D",@volume.timetofull
    end
    should 'correctly populate :encryptkey' do
      assert_equal "29GHT",@volume.encryptkey
    end
    should 'correctly populate :encryptkeypass' do
      assert_equal "MyPass",@volume.encryptkeypass
    end
    should 'correctly populate :volsize' do
      assert_equal "250",@volume.volsize
    end
    should 'correctly populate :path' do
      assert_equal "/var",@volume.path
    end
    should 'correctly populate :baseurl' do
      assert_equal "s3://s3-eu-west-1.amazonaws.com/backups-client",@volume.baseurl
    end
    should 'correctly populate :onefilesystem' do
      assert_equal false,@volume.onefilesystem
    end
  end

  context "Creating the test/etc volume" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"s3://s3-eu-west-1.amazonaws.com/backups-client",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:baseurl=>"test/CheckDuplicity",:sshkeyfile=>"",:onefilesystem=>true}

      @volume=Rasca::DuplicityVolume.new("test/etc",@config_values,@options)
      @volume.testing=true
    end

    should 'correctly populate :name' do
      assert_equal "test_etc",@volume.name
    end
    should 'correctly populate :sshkeyfile' do
      assert_equal "",@volume.sshkeyfile
    end
    should 'correctly populate :timetofull' do
      assert_equal "6D",@volume.timetofull
    end
    should 'correctly populate :encryptkey' do
      assert_equal "292599DD",@volume.encryptkey
    end
    should 'correctly populate :encryptkeypass' do
      assert_equal "TestPass",@volume.encryptkeypass
    end
    should 'correctly populate :volsize' do
      assert_equal "250",@volume.volsize
    end
    should 'correctly populate :path' do
      assert_equal "test/etc",@volume.path
    end
    should 'correctly populate :baseurl' do
      assert_equal "test/CheckDuplicity",@volume.baseurl
    end
    should 'correctly populate :onefilesystem' do
      assert_equal true,@volume.onefilesystem
    end
  end

  context "Creating the / (root) volume" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"file://dat/bck",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",
                        :timetofull=>"6D", :archivedir=>"/var/cache/duplicity"}
      @options={:name=>"root",:timetofull=>"15D",:volsize=>"25"}

      @volume=Rasca::DuplicityVolume.new("/",@config_values,@options)
      @volume.testing=true
    end

    ## Command line
    should 'correctly create the backup cmd with all options' do
      cmd="/usr/bin/duplicity inc --tempdir /var/tmp --archive-dir /var/cache/duplicity --ssh-options=-oIdentityFile=/root/.ssh/id_dsa --full-if-older-than 15D --encrypt-key 292599DD --volsize 25 --exclude-other-filesystems --name root / file://dat/bck/root"
      assert_equal cmd, @volume.gencmd("inc")
    end

  end

  context "Creating the / (root) volume" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"file://dat/bck",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:name=>"root",:timetofull=>"15D",:volsize=>"25"}

      @volume=Rasca::DuplicityVolume.new("/",@config_values,@options)
      @volume.testing=true
    end

    ## Command line
    should 'correctly create the backup cmd with empty archivedir' do
      cmd="/usr/bin/duplicity inc --tempdir /var/tmp --ssh-options=-oIdentityFile=/root/.ssh/id_dsa --full-if-older-than 15D --encrypt-key 292599DD --volsize 25 --exclude-other-filesystems --name root / file://dat/bck/root"
      assert_equal cmd, @volume.gencmd("inc")
    end

  end

  context "Creating a volume with onefilesystem=false" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"file://dat/bck",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:name=>"root",:timetofull=>"15D",:volsize=>"25",:onefilesystem=>false}

      @volume=Rasca::DuplicityVolume.new("/",@config_values,@options)
      @volume.testing=true
    end

    ## Command line
    should 'correctly create the backup cmd without --exclude-other-filesystems option' do
      cmd="/usr/bin/duplicity inc --tempdir /var/tmp --ssh-options=-oIdentityFile=/root/.ssh/id_dsa --full-if-older-than 15D --encrypt-key 292599DD --volsize 25 --name root / file://dat/bck/root"
      assert_equal cmd, @volume.gencmd("inc")
    end

  end

  context "Creating a volume with empty :encryptkey" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"file://dat/bck",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",
                        :timetofull=>"6D",:archivedir=>"/var/cache/duplicity"}
      @options={:name=>"root",:volsize=>"25",:encryptkey=>"",:sshkeyfile=>"/root/.ssh/backup_dsa"}

      @volume=Rasca::DuplicityVolume.new("/",@config_values,@options)
      @volume.testing=true
    end

    ## Command line
    should 'correctly create the backup cmd with --no-encryption option' do
      cmd="/usr/bin/duplicity inc --tempdir /var/tmp --archive-dir /var/cache/duplicity --ssh-options=-oIdentityFile=/root/.ssh/backup_dsa --full-if-older-than 6D --no-encryption --volsize 25 --exclude-other-filesystems --name root / file://dat/bck/root"
      assert_equal cmd, @volume.gencmd("inc")
    end

  end

  context "Creating a volume with empty :sshkeyfile" do
    setup do
      @config_values={ :encryptkey=>"292599DD",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"file://dat/bck",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",
                        :timetofull=>"6D",:archivedir=>"/var/cache/duplicity"}
      @options={:name=>"root",:volsize=>"25",:encryptkey=>"",:sshkeyfile=>""}

      @volume=Rasca::DuplicityVolume.new("/",@config_values,@options)
      @volume.testing=true
    end

    ## Command line
    should 'correctly create the backup cmd with no --ssh-options option' do
      cmd="/usr/bin/duplicity inc --tempdir /var/tmp --archive-dir /var/cache/duplicity --full-if-older-than 6D --no-encryption --volsize 25 --exclude-other-filesystems --name root / file://dat/bck/root"
      assert_equal cmd, @volume.gencmd("inc")
    end

  end

  context "Creating a simple volume" do
    setup do
      @config_values={ :encryptkey=>"",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"s3://s3-eu-west-1.amazonaws.com/backups-client",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:baseurl=>"file://test/CheckDuplicity",:sshkeyfile=>"",:onefilesystem=>true}

      @volume=Rasca::DuplicityVolume.new("test/etc",@config_values,@options)
      @volume.debug=true
      @volume.testing=false
    end

    ## Command line
    should 'correctly create the backup cmd' do
      cmd="/usr/bin/duplicity inc --tempdir /var/tmp --full-if-older-than 6D --no-encryption --volsize 250 --exclude-other-filesystems --name test_etc test/etc file://test/CheckDuplicity/test_etc"
      assert_equal cmd, @volume.gencmd("inc")
    end

    should 'correctly create the collection cmd' do
      cmd="/usr/bin/duplicity col --tempdir /var/tmp --full-if-older-than 6D --no-encryption --volsize 250 --exclude-other-filesystems --name test_etc file://test/CheckDuplicity/test_etc"
      assert_equal cmd, @volume.gencmd("col")
    end

    should 'correctly create the list cmd' do
      cmd="/usr/bin/duplicity list --tempdir /var/tmp --full-if-older-than 6D --no-encryption --volsize 250 --exclude-other-filesystems --name test_etc file://test/CheckDuplicity/test_etc"
      assert_equal cmd, @volume.gencmd("list")
    end
  end

  context "Checking the volume collection" do
    setup do
      @config_values={ :encryptkey=>"",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"s3://s3-eu-west-1.amazonaws.com/backups-client",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:baseurl=>"file://test/CheckDuplicity",:sshkeyfile=>"",:onefilesystem=>true}
      @volume=Rasca::DuplicityVolume.new("test/etc",@config_values,@options)
      @volume.debug=true
      @volume.testing=false
    end

    should "correctly parse collection output" do
      chain=@volume.parse_collection_output(File.read("test/CheckDuplicity/collection_output/duplicity_col_output.txt"))
      assert_equal 6,chain[:backup_sets],"Sets should be 6"
      assert_equal 14,chain[:volumes],"Volumes should be 14"
      assert_equal Time.mktime(2012,7,4,3,59,0),chain[:starttime],"Start time"
      assert_equal Time.mktime(2012,7,9,3,43,03),chain[:endtime],"End time"
      assert_equal 6,chain[:sets].keys.size,"Sets sould have 6 entries"
    end

  end

  context "Creating a test backup of test/etc" do
    setup do
      @config_values={ :encryptkey=>"",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"s3://s3-eu-west-1.amazonaws.com/backups-client",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:baseurl=>"file://test/CheckDuplicity",:sshkeyfile=>"",:onefilesystem=>true}
      @volume=Rasca::DuplicityVolume.new("test/etc",@config_values,@options)
      @volume.debug=true
      @volume.testing=false
    end

    should '01 create a correct initial full backup' do
      FileUtils.rm_rf "test/CheckDuplicity/test_etc"
      assert_equal 0,@volume.run("inc")
    end

    should '02 correctly list the collection' do
      assert_equal 0,@volume.run("col")
    end

    should '03 create a correct incremental backup' do
      assert_equal 0,@volume.run("inc")
    end

    should '04 correctly list the collection' do
      puts @full_tstamp
      assert_equal 0,@volume.run("col")
      assert_equal true,@volume.last_full>Time.now-15,"Last full within 15 seconds"
      assert_equal true,@volume.last_incremental>Time.now-15,"Last incremental within 15 seconds"
    end

    should '05 correctly list the files' do
      assert_equal 0,@volume.run("list")
    end

    #should "return 127 when dirvish binary does not exist" do
    #  @options={:baseurl=>"file://test/CheckDuplicity",:sshkeyfile=>"",:duplicity=>"/usr/bin/nonexistent"}
    #  @volume=Rasca::DuplicityVolume.new("test/etc",@config_values,@options)
    #  @volume.debug=true
    #  @volume.testing=false
    #  assert_equal 127,@volume.run("inc")
    #end

    should "return 13 when backup source does not exist" do
      @options={:baseurl=>"file://test/CheckDuplicity",:sshkeyfile=>""}
      @volume=Rasca::DuplicityVolume.new("test/etc/NONEXISTENT",@config_values,@options)
      @volume.debug=true
      @volume.testing=false
      assert_equal 13,@volume.run("inc")
    end

    should "detect empty backups" do
      @options={:baseurl=>"file://test/CheckDuplicity",:sshkeyfile=>"",:name=>"empty_bck"}
      @volume=Rasca::DuplicityVolume.new("test/CheckDuplicity/empty",@config_values,@options)
      @volume.debug=true
      @volume.testing=false
      assert_equal 128,@volume.run("inc")
    end

  end

end
