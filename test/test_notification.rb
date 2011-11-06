require "helper"

class TestNotification < Test::Unit::TestCase

  context "Notifications class" do
    setup do
      @notification = Rasca::Notification.new("Test","modularit.test",{:print => "", :nsca => "nscaserver.mydomain.com"})
    end

    should 'initialize messages correctly' do
      assert_equal "", @notification.short
      assert_equal "", @notification.long
    end

    should 'set messages correctly' do
      @notification.short="TEST"
      @notification.long="TEST"
      assert_equal "TEST", @notification.short
      assert_equal "TEST", @notification.long
    end

    should 'add strings to short messages' do
      @notification.short+="one,"
      @notification.short+="two,"
      @notification.short+="three"
      puts @notification.short
      assert_equal "one,two,three", @notification.short
    end
    
    should 'add strings to long messages' do
      @notification.long+="one\n"
      @notification.long+="two\n"
      @notification.long+="three\n"
      puts @notification.long
      assert_equal "one\ntwo\nthree\n", @notification.long
    end

    should "raise exception if invalid method" do
      assert_raise RuntimeError do
        @notification = Rasca::Notification.new("Test","modularit.test",{:print => "", :none => nil})
      end
    end

    should "correctly initialize notification objects" do
      assert_respond_to @notification.notifications[0],:notify
      assert_respond_to @notification.notifications[1],:notify
    end

  end

  context "NotifyNSCA class" do
    setup do
      @notify = Rasca::NotifyNSCA.new("TestNSCA","modularit.test","nscaserver.mydomain.com")
    end

    should "correctly initialize nsca_cmd when no path specified" do
      assert_equal "/usr/bin/send_nsca -H nscaserver.mydomain.com -c /etc/modularit/send_nsca.cfg", @notify.nsca_cmd
    end

    should "correctly initialize nsca_cmd when path and config are specified" do
      @notify.nsca_path="/usr/local/bin/send_nsca"
      @notify.nsca_conf="/etc/nagios/send_nsca.cfg"
      assert_equal "/usr/local/bin/send_nsca -H nscaserver.mydomain.com -c /etc/nagios/send_nsca.cfg", @notify.nsca_cmd
    end

    should "correctly map status to nagios retcodes" do
      assert_equal 0,@notify.retcode("OK")
      assert_equal 0,@notify.retcode("CORRECTED")
      assert_equal 1,@notify.retcode("WARNING")
      assert_equal 2,@notify.retcode("CRITICAL")
      assert_equal 3,@notify.retcode("UNKNOWN")
    end

    should "correctly generate the notify_msg" do
      assert_equal "modularit.test\tTestNSCA\t0\tOK: It works",@notify.notify_msg("OK","OK: It works",nil)
    end

  end
end
