require "helper"

class TestCheckFake < Test::Unit::TestCase

  context "When we create a Rasca::CheckFake object with OK status, it" do

    setup do
      @check=Rasca::CheckFake.new("TestChk","OK","test/etc")
    end

    should 'return a RascaCheckFake object' do
      assert_instance_of Rasca::CheckFake, @check
    end

    should "have initial OK status" do
      assert_equal "OK", @check.status
    end

    should "have the name passed on creation: TestChk" do
      assert_equal "TestChk", @check.name
    end

    should "have debug = false" do
      assert_equal false,@check.debug
    end

    should "have verbose = false" do
      assert_equal false,@check.verbose
    end

    should "change status when using setstatus" do
      @check.setstatus("OK")
      assert_equal "OK",@check.status
      @check.setstatus("CRITICAL")
      assert_equal "CRITICAL",@check.status
      @check.setstatus("WARNING")
      assert_equal "WARNING",@check.status
    end

    should "raise exception when setstatus with invalid status" do
      assert_raise RuntimeError do
        @check.setstatus("NONEXISTENT")
      end
    end

    should "raise exception when incstatus with invalid status" do
      assert_raise RuntimeError do
        @check.incstatus("NONEXISTENT")
      end
    end
  end

end
