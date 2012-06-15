require "helper"
require "syslog"

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

  context "NotifyEMail class" do
    should "correctly initialize email and mail_cmd when not defined" do
      @notify = Rasca::NotifyEMail.new("TestEMail","modularit.test",{})
      assert_equal "root@localhost", @notify.address
      assert_equal "/usr/sbin/sendmail -t", @notify.mail_cmd
    end

    should "correctly initialize email and mail_cmd when defined" do
      @notify = Rasca::NotifyEMail.new("TestEMail","modularit.test",{ :address => "test@mydomain.not",
                                                                    :mail_cmd => "/usr/lib/sendmail -t"})
      assert_equal "test@mydomain.not", @notify.address
      assert_equal "/usr/lib/sendmail -t", @notify.mail_cmd
    end

    should "should notify if status=CRITICAL and mail_level=WARNING" do
      @notify = Rasca::NotifyEMail.new("TestEMail","modularit.test",{ :address => "test@mydomain.not",
                                                                    :mail_level => "WARNING",
                                                                    :mail_cmd => "/usr/lib/sendmail -t"})
      assert_equal true, @notify.notify("CRITICAL","short","this is a long\nmessage\n")
    end

    should "should NOT notify if status=OK and mail_level=WARNING" do
      @notify = Rasca::NotifyEMail.new("TestEMail","modularit.test",{ :address => "test@mydomain.not",
                                                                    :mail_level => "WARNING",
                                                                    :mail_cmd => "/usr/lib/sendmail -t"})
      assert_equal false, @notify.notify("OK","short","this is a long\nmessage\n")
    end

    should "generate correct email message" do
      @notify = Rasca::NotifyEMail.new("TestEMail","modularit.test",{ :address => "test@mydomain.not",
                                                                    :mail_cmd => "/bin/cat > test/TestEMail/output.txt"})
      message=
"To: test@mydomain.not
Subject: Rasca alert TestEMail CRITICAL at modularit.test

Host: modularit.test
Alert TestEMail: CRITICAL
---
one
two
three
"
      assert_equal message,@notify.create_mail("CRITICAL","short","one\ntwo\nthree\n")
    end

    should "create correct output file" do
      @notify = Rasca::NotifyEMail.new("TestEMail","modularit.test",{ :address => "test@mydomain.not",
                                                                    :mail_cmd => "/bin/cat > test/TestEMail/output.txt"})
      md5sample=Digest::MD5.hexdigest(File.read("test/TestEMail/test.txt"))
      @notify.notify("CRITICAL","short","this is a long\nmessage\n")
      md5output=Digest::MD5.hexdigest(File.read("test/TestEMail/output.txt"))
      assert_equal md5sample,md5output
    end

  end

  context "NotifySyslog class" do

    should "should notify if status=CRITICAL and syslog_level=WARNING" do
      @notify = Rasca::NotifySyslog.new("TestSyslog","modularit.test",{ :syslog_level => "WARNING" })
      assert_equal true, @notify.notify("CRITICAL","short message","this is a long\nmessage\n")
    end

    should "should NOT notify if status=WARNING and syslog_level=CRTICAL" do
      @notify = Rasca::NotifySyslog.new("TestSyslog","modularit.test",{ :syslog_level => "CRITICAL" })
      assert_equal false, @notify.notify("WARNING","short message","this is a long\nmessage\n")
    end
  end

end

