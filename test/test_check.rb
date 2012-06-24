require "helper"
require "fileutils"

class TestCheck < Test::Unit::TestCase

  context "When we create a Rasca::Check object, it" do

    setup do
      @check=Rasca::Check.new("TestChk","test/etc")
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
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
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
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
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
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
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
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
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
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
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
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
    end

    should "set status UNKNOWN" do
      @check.check
      assert_equal "UNKNOWN",@check.status
    end

  end

  context "Method report" do
    setup do
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
    end

    should "add message to @long when report_level=OK and status=OK" do
      @check.long=""
      @check.report_level="OK"
      assert_equal "message added",@check.report("OK","message added")
    end 

    should "NOT add message to @long when report_level=WARNING and status=OK" do
      @check.long=""
      @check.report_level="WARNING"
      assert_equal "",@check.report("OK","message added")
    end 

    should "NOT add message to @long when report_level=CRITICAL and status=OK" do
      @check.long=""
      @check.report_level="CRITICAL"
      assert_equal "",@check.report("OK","message added")
    end 

    should "add message to @long when report_level=WARNING and status=WARNING" do
      @check.long=""
      @check.report_level="WARNING"
      assert_equal "message added",@check.report("WARNING","message added")
    end 

    should "NOT add message to @long when report_level=CRITICAL and status=WARNING" do
      @check.long=""
      @check.report_level="CRITICAL"
      assert_equal "",@check.report("WARNING","message added")
    end 

    should "add message to @long when report_level=CRITICAL and status=CRITICAL" do
      @check.long=""
      @check.report_level="CRITICAL"
      assert_equal "message added",@check.report("CRITICAL","message added")
    end 

  end

  context "A Check instance" do

    should "00 initial last_status should be OK" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.setstatus("WARNING")
      assert_equal "OK",@check.last_status
      @check.close
    end

    should "01 remind it's last status (WARNING)" do
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.setstatus("OK")
      assert_equal "WARNING",@check.last_status 
      @check.close
    end

    should "02 remind it's last status (OK)" do
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.setstatus("CRITICAL")
      assert_equal "OK",@check.last_status 
      @check.close
    end

    should "03 remind it's last status (CRITICAL)" do
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.setstatus("OK")
      assert_equal "CRITICAL",@check.last_status 
      @check.close
    end

    should "update status_last_change" do
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      tstamp=Time.now.to_i
      @check.setstatus("OK")
      assert_equal tstamp,@check.status_last_change
    end

    should "set status_change_time" do
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.status_change_time=3
      assert_equal 3,@check.status_change_limit
    end

    should "update status_change count" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.status_change_time=15
      @check.setstatus("OK")
      @check.setstatus("WARNING")
      @check.setstatus("OK")
      assert_equal 3,@check.status_change_count
    end

    should "reset status_change_count when status_change_time passes" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.status_change_time=3
      @check.setstatus("OK")
      @check.setstatus("WARNING")
      sleep(3)
      @check.setstatus("OK")
      assert_equal 1,@check.status_change_count
    end

    should "detect when its flapping" do
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.status_change_limit=3
      @check.status_change_time=3
      @check.setstatus("OK")
      @check.setstatus("WARNING")
      @check.setstatus("OK")
      assert_equal true,@check.is_flapping?
    end

    should "NOT detect flapping when time limit passes" do
      FileUtils.rm_f "test/data/TestChk/Check.yml"
      @check=Rasca::Check.new("TestChk","test/etc",true,true)
      @check.status_change_limit=3
      @check.status_change_time=3
      @check.setstatus("OK")
      @check.setstatus("WARNING")
      sleep(3)
      @check.setstatus("OK")
      assert_equal false,@check.is_flapping?
    end
  end

end

