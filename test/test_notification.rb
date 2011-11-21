require "helper"

class TestNotification < Test::Unit::TestCase

  context "Notifications class" do
    setup do
      @check = Rasca::Check.new("Test","test/etc",true,true)
      @check.hostname="modularit.test"
      @check.initNotifications({:print => nil, :nsca => { :server => "nscaserver.mydomain.com"}})
    end

    should 'initialize messages correctly' do
      assert_equal "", @check.short
      assert_equal "", @check.long
    end

    should 'set messages correctly' do
      @check.short="TEST"
      @check.long="TEST"
      assert_equal "TEST", @check.short
      assert_equal "TEST", @check.long
    end

    should 'add strings to short messages' do
      @check.short+="one,"
      @check.short+="two,"
      @check.short+="three"
      assert_equal "one,two,three", @check.short
    end
    
    should 'add strings to long messages' do
      @check.long+="one\n"
      @check.long+="two\n"
      @check.long+="three\n"
      assert_equal "one\ntwo\nthree\n", @check.long
    end

    should "raise exception if invalid method" do
      assert_raise RuntimeError do
        @check.initNotifications({:print => "", :none => nil})
      end
    end

    should "correctly initialize notification objects" do
      assert_respond_to @check.notifications[0],:notify
      assert_respond_to @check.notifications[1],:notify
    end

  end

  context "NotifyNSCA class" do
    setup do
      @notify = Rasca::NotifyNSCA.new("TestNSCA","modularit.test",{ :server => "nscaserver.mydomain.com" })
    end

    should "correctly initialize nsca_cmd when no path specified" do
      assert_equal "/usr/sbin/send_nsca -H nscaserver.mydomain.com -c /etc/modularit/send_nsca.cfg", @notify.nsca_cmd
    end

    should "correctly initialize nsca_cmd when path and config are specified" do
      @notify = Rasca::NotifyNSCA.new("TestNSCA","modularit.test",{ :server => "nscaserver.mydomain.com",
                                                                    :nsca_path => "/usr/local/bin/send_nsca",
                                                                    :nsca_conf => "/etc/nagios/send_nsca.cfg"})
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
