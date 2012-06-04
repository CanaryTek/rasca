require "helper"

class TestCheckDirUsage < Test::Unit::TestCase

  context "CheckDirUsage when using usage_bigger" do

    setup do
      @check=Rasca::CheckDirUsage.new("CheckDirUsage","test/etc",true,true)
    end

    should 'find 2G bigger than 1G' do
      assert_equal true, @check.usage_bigger("2G","1G")
    end

    should 'find 2M bigger than 1M' do
      assert_equal true, @check.usage_bigger("2M","1M")
    end

    should 'find 2K bigger than 1K' do
      assert_equal true, @check.usage_bigger("2K","1K")
    end

    should 'find 1G smaller than 2G' do
      assert_equal false, @check.usage_bigger("1G","2G")
    end

    should 'find 1G bigger than 2M' do
      assert_equal true, @check.usage_bigger("1G","2M")
    end

    should 'find 1G bigger than 2K' do
      assert_equal true, @check.usage_bigger("1G","2K")
    end

    should 'find 1M bigger than 2K' do
      assert_equal true, @check.usage_bigger("1M","2K")
    end

    should 'find 2M smaller than 1G' do
      assert_equal false, @check.usage_bigger("2M","1G")
    end

    should 'find 2K smaller than 1G' do
      assert_equal false, @check.usage_bigger("2K","1G")
    end

    should 'find 2K smaller than 1M' do
      assert_equal false, @check.usage_bigger("2K","1M")
    end
 
  end

end
