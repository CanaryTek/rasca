require "helper"

class TestCheckSecPkg < Test::Unit::TestCase

  context "An instance of CheckSecPkg" do
    setup do
      @check=Rasca::CheckSecPkg.new("CheckSecPkg","test/etc",true,true)
      @check.testing=true
      @check.ports_cmd="cat test/CheckSecPkg/lsof_simple.txt"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecPkg")
      @check.check_update_cmd="/bin/false"
      @check.check
    end

    should 'create open ports list' do
      result=[ {:proc => "ntpd", :port => "123", :proto => "UDP"},
              {:proc => "sshd", :port => "22", :proto => "TCP"},
              ]
      assert_equal result, @check.openPorts
    end

    should 'create list of packages' do
      result=[ {:proc => "ntpd", :port => "123", :proto => "UDP"},
              {:proc => "sshd", :port => "22", :proto => "TCP"},
              ]
      assert_equal ["ntp","openssh-server"], @check.packageList
    end

  end

  context "CheckSecPkg with unknown processes" do
    setup do
      @check=Rasca::CheckSecPkg.new("CheckSecPkg","test/etc",true,true)
      @check.testing=true
      @check.ports_cmd="cat test/CheckSecPkg/lsof_unknown.txt"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecPkg")
      @check.check_update_cmd="/bin/false"
      @check.check
    end

    should 'set status=CRITICAL when unknown open port found' do
      assert_equal "CRITICAL",@check.status
    end

    should 'return unknown ports' do
      result = [{:proc => "telnet", :port => "23", :proto => "TCP"}]
      assert_equal result,@check.getUnknownPorts
    end

  end

  context "CheckSecPkg with NO packages to update" do
    setup do
      @check=Rasca::CheckSecPkg.new("CheckSecPkg","test/etc",true,true)
      @check.testing=true
      @check.ports_cmd="cat test/CheckSecPkg/lsof_simple.txt"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecPkg")
      @check.check_update_cmd="/bin/true"
      @check.check
    end

    should 'set status=OK when NO packages need update' do
      assert_equal "OK",@check.status
    end

    should 'return empty package list to update' do
      assert_equal [],@check.packagesToUpdate
    end

  end

  context "CheckSecPkg with known processes but not matching ports" do
    setup do
      @check=Rasca::CheckSecPkg.new("CheckSecPkg","test/etc",true,true)
      @check.testing=true
      @check.ports_cmd="cat test/CheckSecPkg/lsof_non_matching_ports.txt"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecPkg")
      @check.check_update_cmd="/bin/false"
      @check.check
    end

    should 'set status=CRITICAL when unknown open port found' do
      assert_equal "CRITICAL",@check.status
    end

    should 'return unknown ports' do
      result = [{:proc => "sshd", :port => "10022", :proto => "TCP"}]
      assert_equal result,@check.getUnknownPorts
    end

  end

   context "CheckSecPkg with a known process with ANY in ports" do
    setup do
      @check=Rasca::CheckSecPkg.new("CheckSecPkg","test/etc",true,true)
      @check.testing=true
      @check.ports_cmd="cat test/CheckSecPkg/lsof_any_ports.txt"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecPkg")
      @check.check_update_cmd="/bin/false"
      @check.check
    end

    should 'set status=OK when the known process listens on ANY port' do
      assert_equal "WARNING",@check.status
    end

    should 'not mark the port as unknown' do
      assert_equal [],@check.getUnknownPorts
    end

  end

  context "CheckSecPkg with packages to update" do
    setup do
      @check=Rasca::CheckSecPkg.new("CheckSecPkg","test/etc",true,true)
      @check.testing=true
      @check.ports_cmd="cat test/CheckSecPkg/lsof_simple.txt"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecPkg")
      @check.check_update_cmd="/bin/false"
      @check.check
    end

    should 'set status=WARNING when packages need update' do
      assert_equal "WARNING",@check.status
    end

    should 'return packages to update' do
      assert_equal ["ntp","openssh-server"],@check.packagesToUpdate
    end
  end

  context "CheckSecPkg with no package a ANY ports" do
    setup do
      @check=Rasca::CheckSecPkg.new("CheckSecPkg","test/etc",true,true)
      @check.testing=true
      @check.ports_cmd="cat test/CheckSecPkg/lsof_no_packages.txt"
      @check.object_dir="test/objects"
      @check.readObjects("CheckSecPkg")
      @check.check_update_cmd="/bin/false"
      @check.check
    end

    should 'set status=OK and NOT check for updates on that package' do
      assert_equal "OK",@check.status
    end

    should 'return packages to update' do
      assert_equal [],@check.packagesToUpdate
    end

    should 'not mark the port as unknown' do
      assert_equal [],@check.getUnknownPorts
    end
  end


  # detect 

end
