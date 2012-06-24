require "helper"

class TestCheckPgXlogReplication < Test::Unit::TestCase

  context "An instance of CheckPgXlogReplication" do

    setup do
      @check=Rasca::CheckPgXlogReplication.new("CheckPgXlogReplication","test/etc",true,true)
      @check.object_dir="test/CheckPgXlogReplication/objects/default_delays"
    end

    should 'correctly read the master xlog file' do
      @check.testing="test/CheckPgXlogReplication/nosync_3"
      assert_equal "0000000100000DD30000005A", @check.getMasterXlog("masterhost")
    end

    should 'correctly read the slave xlog file' do
      @check.testing="test/CheckPgXlogReplication/nosync_3"
      assert_equal "0000000100000DD300000057", @check.getSlaveXlog
    end

    should 'set status=OK if xlog files are equal' do
      @check.testing="test/CheckPgXlogReplication/insync"
      @check.check
      assert_equal "OK", @check.status
    end

    should 'set status=CRITICAL if master is behind slave' do
      @check.testing="test/CheckPgXlogReplication/masterbehind"
      @check.check
      assert_equal "CRITICAL", @check.status
    end


  end

  context "CheckPgXlogReplication with default delay values warning=5 critical=10" do

    setup do
      @check=Rasca::CheckPgXlogReplication.new("CheckPgXlogReplication","test/etc",true,true)
      @check.object_dir="test/CheckPgXlogReplication/objects/default_delays"
    end

    should 'set status=OK if slave is behind (3) less than warning_delay' do
      @check.testing="test/CheckPgXlogReplication/nosync_3"
      @check.check
      assert_equal "OK", @check.status
    end

    should 'set status=WARNING if slave is behind (6) more than warning_delay' do
      @check.testing="test/CheckPgXlogReplication/nosync_6"
      @check.check
      assert_equal "WARNING", @check.status
    end

    should 'set status=CRITICAL if slave is behind (12) more than critical_delay' do
      @check.testing="test/CheckPgXlogReplication/nosync_12"
      @check.check
      assert_equal "CRITICAL", @check.status
    end

  end

  context "CheckPgXlogReplication with configured delay warning=7 critical=15" do

    setup do
      @check=Rasca::CheckPgXlogReplication.new("CheckPgXlogReplication","test/etc",true,true)
      @check.object_dir="test/CheckPgXlogReplication/objects/configured_delays"
    end

    should 'set status=OK if slave is behind (6) less than warning_delay (6)' do
      @check.testing="test/CheckPgXlogReplication/nosync_6"
      @check.check
      assert_equal "OK", @check.status
    end

    should 'set status=WARNING if slave is behind (12) more than warning_delay' do
      @check.testing="test/CheckPgXlogReplication/nosync_12"
      @check.check
      assert_equal "WARNING", @check.status
    end

    should 'set status=CRITICAL if slave is behind (15) more than critical_delay' do
      @check.testing="test/CheckPgXlogReplication/nosync_15"
      @check.check
      assert_equal "CRITICAL", @check.status
    end

  end


  context "CheckPgXlogReplication running commands" do

    setup do
      @check=Rasca::CheckPgXlogReplication.new("CheckPgXlogReplication","test/etc",true,true)
      @check.object_dir="test/CheckPgXlogReplication/objects/configured_delays"
    end

    should 'set status=CRITICAL if getMasterXlog fails' do
      @check.check
      assert_equal "CRITICAL", @check.status
    end

    should 'set status=CRITICAL if getSlaveXlog fails' do
      @check.check
      assert_equal "CRITICAL", @check.status
    end

  end
end
