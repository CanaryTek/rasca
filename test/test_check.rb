require "helper"

class TestCheck < Test::Unit::TestCase

  context "When we create a Rasca::Check object, it" do

    setup do
      @check=Rasca::Check.new("TestChk")
    end

    should 'return a RascaCheck object' do
      assert_instance_of Rasca::Check, @check
    end

    should "have initial UNKNOWN status" do
      assert_equal "UNKNOWN", @check.status
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

  context "In status UNKNOWN method incstatus" do
    setup do
      @check=Rasca::Check.new("TestChk")  
      @check.debug=true
    end

    # Unknown
    should "go from UNKNOWN to OK" do
      @check.incstatus("OK")
      assert_equal "OK",@check.status
    end
  end

  context "In status OK method incstatus" do
    setup do
      @check=Rasca::Check.new("TestChk")  
      @check.debug=true
      @check.setstatus("OK")
    end

    # From OK
    should "NOT go from OK to UNKNOWN" do
      @check.incstatus("UNKNOWN")
      assert_equal "OK",@check.status
    end
    should "go from OK to CORRECTED" do
      @check.incstatus("CORRECTED")
      assert_equal "CORRECTED",@check.status
    end
    should "go from OK to WARNING" do
      @check.setstatus("OK")
      @check.incstatus("WARNING")
      assert_equal "WARNING",@check.status
    end
    should "go from OK to CRITICAL" do
      @check.setstatus("OK")
      @check.incstatus("CRITICAL")
      assert_equal "CRITICAL",@check.status
    end
  end

  context "In status CORRECTED method incstatus" do
    setup do
      @check=Rasca::Check.new("TestChk")  
      @check.debug=true
      @check.setstatus("CORRECTED")
    end
    # From CORRECTED
    should "NOT go from CORRECTED to UNKNOWN" do
      @check.incstatus("UNKNOWN")
      assert_equal "CORRECTED",@check.status
    end
    should "NOT go from CORRECTED to OK" do
      @check.incstatus("CORRECTED")
      assert_equal "CORRECTED",@check.status
    end
    should "go from CORRECTED to WARNING" do
      @check.incstatus("WARNING")
      assert_equal "WARNING",@check.status
    end
    should "go from CORRECTED to CRITICAL" do
      @check.incstatus("CRITICAL")
      assert_equal "CRITICAL",@check.status
    end
  end

  context "In status WARNING method incstatus" do
    setup do
      @check=Rasca::Check.new("TestChk")  
      @check.debug=true
      @check.setstatus("WARNING")
    end
    # From WARNING
    should "NOT go from WARNING to UNKNOWN" do
      @check.incstatus("UNKNOWN")
      assert_equal "WARNING",@check.status
    end
    should "NOT go from WARNING to OK" do
      @check.incstatus("OK")
      assert_equal "WARNING",@check.status
    end
    should "NOT go from WARNING to CORRECTED" do
      @check.incstatus("CORRECTED")
      assert_equal "WARNING",@check.status
    end
    should "go from WARNING to CRITICAL" do
      @check.incstatus("CRITICAL")
      assert_equal "CRITICAL",@check.status
    end
  end

  context "In status CRITICAL method incstatus" do
    setup do
      @check=Rasca::Check.new("TestChk")  
      @check.debug=true
      @check.setstatus("CRITICAL")
    end
    # From CRITICAL
    should "NOT go from CRITICAL to UNKNOWN" do
      @check.incstatus("UNKNOWN")
      assert_equal "CRITICAL",@check.status
    end
    should "NOT go from CRITICAL to OK" do
      @check.incstatus("OK")
      assert_equal "CRITICAL",@check.status
    end
    should "NOT go from CRITICAL to CORRECTED" do
      @check.incstatus("CORRECTED")
      assert_equal "CRITICAL",@check.status
    end
    should "NOT go from CRITICAL to WARNING" do
      @check.incstatus("WARNING")
      assert_equal "CRITICAL",@check.status
    end
  end

  context "Default check method" do
    setup do
      @check=Rasca::Check.new("TestChk")
    end

    should "set status UNKNOWN" do
      @check.check
      assert_equal "UNKNOWN",@check.status
    end

  end

end
