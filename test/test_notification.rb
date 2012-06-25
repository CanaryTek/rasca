require "helper"
require "syslog"
require 'digest/md5'
require 'fileutils'

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

  context "Notify superclass" do
    setup do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",nil,{:data_dir => "test/Notifications/data"})
    end

    should "should notify if status=CRITICAL and notify_level=WARNING" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "WARNING"}, 
                                                                {:data_dir => "test/Notifications/data" })
      assert_equal true, @notify.notify("CRITICAL","short","this is a long\nmessage\n")
    end

    should "should NOT notify if status=OK and notify_level=WARNING" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "WARNING"}, 
                                                                {:data_dir => "test/Notifications/data" })
      assert_equal false, @notify.notify("OK","short","this is a long\nmessage\n")
    end

    should "should NOT notify if status=WARNING and notify_level=CRITICAL" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{:notify_level => "CRITICAL"}, 
                                                                {:last_status => "WARNING", :data_dir => "test/Notifications/data" })
      assert_equal false, @notify.notify("WARNING","short message","this is a long\nmessage\n")
    end

    should "should NOT notify if status=WARNING and notify_level=CRITICAL and last_status=WARNING" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "CRITICAL"},
                                                                {:last_status => "WARNING", :data_dir => "test/Notifications/data" })
      assert_equal false, @notify.notify("WARNING","short message","this is a long\nmessage\n")
    end

    should "should notify if status=WARNING and notify_level=CRITICAL but service is recovering (current status < last status)" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "CRITICAL"}, 
                                                                {:last_status => "CRITICAL", :data_dir => "test/Notifications/data" })
      assert_equal true, @notify.notify("WARNING","short message","this is a long\nmessage\n")
    end

  end

  context "Notify with same status (status=last_status)" do

    # The following tests MUST be in order
    should "01 should notify if persistence file does not exist" do
      FileUtils.rm_f "test/Notifications/data/*"
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "WARNING"}, 
                                                                {:last_status => "CRITICAL", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal true, @notify.notify("CRITICAL","short message","this is a long\nmessage\n")
    end

    should "02 should NOT notify if remind_period has not expired since last notification" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "WARNING", :remind_period => 2000}, 
                                                                {:last_status => "CRITICAL", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal false, @notify.notify("CRITICAL","short message","this is a long\nmessage\n")
    end

    should "03 should notify if remind_period has expired since last notification" do
      sleep(5)
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "WARNING", :remind_period => 5}, 
                                                                {:last_status => "CRITICAL", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal true, @notify.notify("CRITICAL","short message","this is a long\nmessage\n")
    end

  end

  context "Notify with status > last_status" do

    should "notify if status > notify_level" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "CRITICAL", :remind_period => 20}, 
                                                                {:last_status => "OK", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal true, @notify.notify("CRITICAL","short message","this is a long\nmessage\n")
    end

    should "NOT notify if status < notify_level" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{:notify_level => "CRITICAL", :remind_period => 0}, 
                                                                {:last_status => "OK", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal false, @notify.notify("WARNING","short message","this is a long\nmessage\n")
    end

    should "notify even if remind_period has not expired, if status > notify_level (we notify all status changes)" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "CRITICAL", :remind_period => 2000}, 
                                                                {:last_status => "OK", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal true, @notify.notify("CRITICAL","short message","this is a long\nmessage\n")
    end

  end

  context "Notify with status < last_status (recovery)" do
    # Notify ALWAYS

    should "01 notify even if status < notify_level" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "WARNING", :remind_period => 0}, 
                                                                {:last_status => "CRITICAL", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal true, @notify.notify("OK","short message","this is a long\nmessage\n")
    end

    should "02 notify even if remind_period has not expired" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "WARNING", :remind_period => 200000}, 
                                                                {:last_status => "CRITICAL", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal true, @notify.notify("OK","short message","this is a long\nmessage\n")
    end

  end

  context "Notify after recovery" do

    should "01 notify if status > notify_level" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "WARNING", :remind_period => 0}, 
                                                                {:last_status => "OK", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal true, @notify.notify("CRITICAL","short message","this is a long\nmessage\n")
    end

    should "02 NOT notify if status < notify_level" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "CRITICAL", :remind_period => 0}, 
                                                                {:last_status => "OK", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal false, @notify.notify("WARNING","short message","this is a long\nmessage\n")
    end

    should "03 notify even if remind_period has not expired (we notify all status changes)" do
      @notify = Rasca::Notify.new("TestNotify","modularit.test",{ :notify_level => "CRITICAL", :remind_period => 2000000}, 
                                                                {:last_status => "OK", :data_dir => "test/Notifications/data" })
      @notify.debug=true
      assert_equal true, @notify.notify("CRITICAL","short message","this is a long\nmessage\n")
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
      @notify.data_dir="test/Notifications/data"
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
                                                                    :mail_cmd => "/bin/cat > test/TestEMail/output.txt"}, 
                                                                    {:data_dir => "test/Notifications/data"})
      md5sample=Digest::MD5.hexdigest(File.read("test/TestEMail/test.txt"))
      @notify.notify("CRITICAL","short","this is a long\nmessage\n")
      md5output=Digest::MD5.hexdigest(File.read("test/TestEMail/output.txt"))
      assert_equal md5sample,md5output
    end

  end

  context "NotifySyslog class" do

  end

end

