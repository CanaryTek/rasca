require "helper"

class TestCheckSecPkg < Test::Unit::TestCase

  context "An instance of CheckSecPkg" do

    setup do
      @check=Rasca::CheckSecPkg.new("CheckSecPkg","test/etc",true,true)
    end

    should 'create open ports list' do
      result=[ {:proc => "ntpd", :port => "*:123", :proto => "UDP"},
              {:proc => "sshd", :port => "*:22", :proto => "TCP"}
              ]
      @check.testing=true
      @check.ports_cmd="cat test/CheckSecPkg/lsof_simple.txt"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecPkg")
      @check.check
      assert_equal result, @check.getOpenPorts
    end

  end

end
