require "helper"

class TestNotification < Test::Unit::TestCase

  context "Notifications class" do
    setup do
      @notification = Rasca::Notification.new("Test",{:print => "", :nsca => "nscaserver.mydomain.com"})
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
        @notification = Rasca::Notification.new("Test",{:print => "", :none => nil})
      end
    end

    should "correctly initialize notification objects" do
      assert_respond_to @notification.notifications[0],:notify
      assert_respond_to @notification.notifications[1],:notify
    end

  end
end
