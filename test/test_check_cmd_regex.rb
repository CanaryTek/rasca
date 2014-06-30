require "helper"

class TestCheckCmdRegex < Test::Unit::TestCase

  context "An instance of CheckCmdRegex" do

    setup do
      @check=Rasca::CheckCmdRegex.new("CheckCmdRegex","test/etc",true,true)
    end

    should 'return OK when nothing to check' do
      @check.object_dir="test/CheckCmdRegex/objects/empty"
      @check.readObjects("CheckCmdRegex")
      @check.check
      assert_equal "OK", @check.status
    end

    should 'return OK when no regex matches' do
      @check.object_dir="test/CheckCmdRegex/objects/nomatch"
      @check.readObjects("CheckCmdRegex")
      @check.check
      assert_equal "OK", @check.status
    end

    should 'return UNKNOWN when command fails' do
      @check.object_dir="test/CheckCmdRegex/objects/command_error"
      @check.readObjects("CheckCmdRegex")
      @check.check
      assert_equal "UNKNOWN", @check.status
    end

    should 'return WARNING when command fails and status_on_cmd_fail=WARNING' do
      @check.object_dir="test/CheckCmdRegex/objects/command_error_warning"
      @check.readObjects("CheckCmdRegex")
      @check.check
      assert_equal "WARNING", @check.status
    end

    should 'return CRITICAL when command fails and status_on_cmd_fail=CRITICAL' do
      @check.object_dir="test/CheckCmdRegex/objects/command_error_critical"
      @check.readObjects("CheckCmdRegex")
      @check.check
      assert_equal "CRITICAL", @check.status
    end

    should 'return WARNING when regex with status=WARNING found' do
      @check.object_dir="test/CheckCmdRegex/objects/regex_warning"
      @check.readObjects("CheckCmdRegex")
      @check.debug=true
      @check.check
      assert_equal "WARNING", @check.status
    end

    should 'return CRITICAL when regex with status=CRITICAL found' do
      @check.object_dir="test/CheckCmdRegex/objects/regex_critical"
      @check.readObjects("CheckCmdRegex")
      @check.debug=true
      @check.check
      assert_equal "CRITICAL", @check.status
    end


  end

end
