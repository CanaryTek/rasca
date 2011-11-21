require "helper"

class TestCheckRAID < Test::Unit::TestCase

  context "An instance of CheckRAID" do

    setup do
      @check=Rasca::CheckRAID.new("RaidChk","test/etc_default",true,true)
    end

    should 'return OK when all MD arrays are correct' do
      @check.testing="test/CheckRAID/mdstat_ok"
      @check.object_dir="test/objects"
      @check.readObjects("RaidChk")
      @check.check_md
      assert_equal "OK", @check.status
    end

    should 'return CRITICAL when an MD arrays is broken' do
      @check.testing="test/CheckRAID/mdstat_broken"
      @check.readObjects("RaidChk")
      @check.check_md
      assert_equal "CRITICAL", @check.status
    end

    should 'return WARNING on broken md when we force a status for that array in objects file' do
      @check=Rasca::CheckRAID.new("RaidChk","test/etc",true,true)
      @check.testing="test/CheckRAID/mdstat_broken"
      @check.object_dir="test/objects"
      @check.readObjects("RaidChk")
      @check.check_md
      assert_equal "WARNING", @check.status
    end

  end

end
