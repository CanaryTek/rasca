require "helper"
require "syslog"
require 'digest/md5'
require 'fileutils'

class TestCheckNotification < Test::Unit::TestCase

  context "Check notifications" do

    should "00 should notify if status=CRITICAL and notify_level=WARNING" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      @check=Rasca::Check.new("TestChk","test/CheckNotifications/etc/level_warning",true,true)
      @check.status_change_limit=3
      assert_equal true, @check.notifications[0].notify("CRITICAL","short","this is a long\nmessage\n")
    end

    should "01 should NOT notify if status=OK and notify_level=WARNING" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      @check=Rasca::Check.new("TestChk","test/CheckNotifications/etc/level_warning",true,true)
      @check.status_change_limit=3
      @check.setstatus("OK")
      @check.close
      assert_equal false, @check.notifications[0].notify("OK","short","this is a long\nmessage\n")
    end

    should "02 should NOT notify if status=WARNING and notify_level=CRITICAL" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      @check=Rasca::Check.new("TestChk","test/CheckNotifications/etc/level_critical",true,true)
      @check.status_change_limit=3
      @check.setstatus("WARNING")
      @check.close
      assert_equal false, @check.notifications[0].notify("WARNING","short","this is a long\nmessage\n")
    end

    should "03 should NOT notify if status=WARNING and notify_level=CRITICAL and last_status=WARNING" do
      @check=Rasca::Check.new("TestChk","test/CheckNotifications/etc/level_critical",true,true)
      @check.status_change_limit=3
      @check.setstatus("WARNING")
      @check.close
      assert_equal false, @check.notifications[0].notify("WARNING","short","this is a long\nmessage\n")
    end

    should "04 should notify if status=WARNING and notify_level=CRITICAL but service is recovering (current status < last status)" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      @check=Rasca::Check.new("TestChk","test/CheckNotifications/etc/level_critical",true,true)
      @check.status_change_limit=3
      @check.setstatus("OK")
      @check.close
      assert_equal false, @check.notifications[0].notify("OK","short","this is a long\nmessage\n")
    end

    should "05 should notify if persistence file does not exist" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      FileUtils.rm_f "test/data/TestChk/NotifyEMail.yml"
      @check=Rasca::Check.new("TestChk","test/CheckNotifications/etc/remind_period",true,true)
      @check.status_change_limit=3
      @check.setstatus("WARNING")
      @check.close
      assert_equal true, @check.notifications[0].notify("WARNING","short","this is a long\nmessage\n")
    end

    should "06 should NOT notify if remind_period has not expired since last notification" do
      @check=Rasca::Check.new("TestChk","test/CheckNotifications/etc/remind_period",true,true)
      @check.status_change_limit=3
      @check.setstatus("WARNING")
      @check.close
      assert_equal false, @check.notifications[0].notify("WARNING","short","this is a long\nmessage\n")
    end

    should "07 should notify if remind_period has expired since last notification" do
      sleep(5)
      @check=Rasca::Check.new("TestChk","test/CheckNotifications/etc/remind_period",true,true)
      @check.status_change_limit=3
      @check.setstatus("WARNING")
      @check.close
      assert_equal true, @check.notifications[0].notify("WARNING","short","this is a long\nmessage\n")
    end

  end

end

