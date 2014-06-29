require "helper"

class TestCheckPing < Test::Unit::TestCase

  context "An instance of CheckPing" do

    setup do
      @check=Rasca::CheckPing.new("CheckPing","test/etc",true,true)
    end

    should 'return OK when no nodes to check' do
      @check.object_dir="test/CheckPing/objects/empty"
      @check.readObjects("CheckPing")
      @check.check
      assert_equal "OK", @check.status
    end

    should 'return OK when checking localhost' do
      @check.object_dir="test/CheckPing/objects/localhost"
      @check.readObjects("CheckPing")
      @check.check
      assert_equal "OK", @check.status
    end

    should 'return CRITICAL when checking a nonexistent host' do
      @check.object_dir="test/CheckPing/objects/nonexistent"
      @check.readObjects("CheckPing")
      @check.check
      assert_equal "CRITICAL", @check.status
    end

    should 'return WARNING when checking a nonexistent host with forced status=WARNING' do
      @check.object_dir="test/CheckPing/objects/nonexistent_warning"
      @check.readObjects("CheckPing")
      @check.debug=true
      @check.check
      assert_equal "WARNING", @check.status
    end

  end

end
