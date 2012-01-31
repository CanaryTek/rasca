require "helper"

class TestCheckDirvish < Test::Unit::TestCase

  context "An instance of CheckDirvish" do

    setup do
      @check=Rasca::CheckDirvish.new("CheckDirvish","test/etc",true,true)
    end

    should 'return correct banks' do
      assert_equal ["/dat/bck1","/dat/bck2"], @check.readBanks("test/etc/master.conf")
    end

    should 'find correct vaults in bank' do
      assert_equal ["vault2","vault1"], @check.findVaults("test/CheckDirvish/bank")
    end
    
  end

  context "An instance of DirvishVault" do

    setup do
      @check=Rasca::DirvishVault.new("test/CheckDirvish/bank_errors","vault1")
    end

    should 'return correct lastImage' do
      assert_equal "20111219", @check.lastImage
    end

    should 'detect if rsync_error exists' do
      @check=Rasca::DirvishVault.new("test/CheckDirvish/bank_errors","vault1")
      assert_equal true, @check.rsyncError?
    end

    should 'return OK if rsync_error does NOT exists' do
      @check=Rasca::DirvishVault.new("test/CheckDirvish/bank_errors","vault2")
      assert_equal false, @check.rsyncError?
    end

    should 'detect if backup is empty' do
      @check=Rasca::DirvishVault.new("test/CheckDirvish/check_empty","empty")
      @default_empty_level=4
      assert_equal true, @check.isEmpty?
    end

    should 'detect if backup is NOT empty' do
      @check=Rasca::DirvishVault.new("test/CheckDirvish/check_empty","not_empty")
      @default_empty_level=4
      assert_equal false, @check.isEmpty?
    end

    should 'return true if backup is too old' do
      assert_equal true, @check.isOlder?("20111220")
    end
    should 'return false if backup is NOT too old' do
      assert_equal false, @check.isOlder?("20111219")
    end
  end

end
