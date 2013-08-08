require "helper"

class TestCheckDuplicity < Test::Unit::TestCase

=begin
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
=end

  context "An instance of CheckDuplicity without volumes to check" do
    setup do
      @check=Rasca::CheckDuplicity.new("CheckDuplicity","test/etc",true,true)
      @check.testing=false
      @check.debug=true
      @check.object_dir="CheckDuplicity/objects/empty"
    end

    should 'set status OK' do
      @check.check
      assert_equal "OK",@check.status
    end
  end

  context "An instance of CheckDuplicity without backups" do
    setup do
      @check=Rasca::CheckDuplicity.new("CheckDuplicity","test/etc",true,true)
      @check.testing=false
      @check.debug=true
      FileUtils.rm_rf "test/CheckDuplicity/test_etc"
    end

    should 'set status CRITICAL if no nobackup_status is specified' do
      @check.object_dir="test/CheckDuplicity/objects/no_backups"
      @check.check
      assert_equal "CRITICAL",@check.status
    end

    should 'set status to the nobackup_status specified for volume' do
      @check.object_dir="test/CheckDuplicity/objects/no_backups_forced_status"
      @check.check
      assert_equal "WARNING",@check.status
    end
  end

  context "An instance of CheckDuplicity without backups with default nobackup_status" do
    setup do
      @check=Rasca::CheckDuplicity.new("CheckDuplicity","test/CheckDuplicity/etc_nobackup_status",true,true)
      @check.testing=false
      @check.debug=true
      FileUtils.rm_rf "test/CheckDuplicity/test_etc"
    end

    should 'set status to the default nobackup_status if not specified for volume' do
      @check.object_dir="test/CheckDuplicity/objects/no_backups"
      @check.check
      assert_equal "WARNING",@check.status
    end
  end

  context "An instance of CheckDuplicity with valid backups" do
    setup do
      @check=Rasca::CheckDuplicity.new("CheckDuplicity","test/etc",true,true)
      @check.testing=false
      @check.debug=true
      @check.object_dir="test/CheckDuplicity/objects/all_up_to_date"
      # Setup volume
      @config_values={ :encryptkey=>"",:encryptkeypass=>"TestPass",:volsize=>"250",
                        :baseurl=>"s3://s3-eu-west-1.amazonaws.com/backups-client",:sshkeyfile=>"/root/.ssh/id_dsa",
                        :backup_log_dir=>"test/DuplicityVolume/lastbackups",:timetofull=>"6D" }
      @options={:baseurl=>"file://test/CheckDuplicity",:sshkeyfile=>"",:onefilesystem=>true}
      @volume=Rasca::DuplicityVolume.new("test/etc",@config_values,@options)
      @volume.debug=true
      @volume.testing=false
    end

    should 'set status OK if backup newer than warning_limit' do
      FileUtils.rm_rf "test/CheckDuplicity/test_etc"
      assert_equal 0,@volume.run("inc"),"Backup done correctly"
      @check.check
      assert_equal "OK",@check.status
    end

    should 'set status WARNING if backup older than warning_limit but newer than critical_limit' do
      FileUtils.rm_rf "test/CheckDuplicity/test_etc"
      assert_equal 0,@volume.run("inc"),"Backup done correctly"
      sleep 10
      @check.check
      assert_equal "WARNING",@check.status
    end

    should 'set status CRITICAL if backup is older than critical_limit' do
      FileUtils.rm_rf "test/CheckDuplicity/test_etc"
      assert_equal 0,@volume.run("inc"),"Backup done correctly"
      sleep 20
      @check.check
      assert_equal "CRITICAL",@check.status
    end
  end
end
