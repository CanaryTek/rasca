require "helper"

class TestCheckSecUsers < Test::Unit::TestCase

  context "An instance of CheckSecUsers" do

    setup do
      @check=Rasca::CheckSecUsers.new("CheckSecUsers","test/etc",true,true)
    end

    should 'return OK when NO trivial or banned passwords found' do
      @check.testing="test/CheckSecUsers/ok"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecUsers")
      @check.check
      assert_equal "OK", @check.status
    end

    should 'return CRITICAL when trivial passwords found' do
      @check.testing="test/CheckSecUsers/trivial"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecUsers")
      @check.check
      assert_equal "CRITICAL", @check.status
      assert_equal "test1: trivial passwd and valid shell, ", @check.short
    end

    should 'return CRITICAL when banned passwords found' do
      @check.testing="test/CheckSecUsers/banned"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecUsers")
      @check.check
      assert_equal "CRITICAL", @check.status
      assert_equal "root: banned passwd, ", @check.short
    end

    should 'return CRITICAL when banned AND trivial passwords found' do
      @check.testing="test/CheckSecUsers/both"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecUsers")
      @check.check
      assert_equal "CRITICAL", @check.status
      assert_equal "root: banned passwd, test2: trivial passwd, test1: trivial passwd and valid shell, ", @check.short
    end

  end

end
