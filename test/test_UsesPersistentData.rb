require "helper"
require "fileutils"

class TestUsesPersistentData < Test::Unit::TestCase

  context "UsesPersistentData module" do
    setup do
      @data={ :variable1 => "Variable1", :variable2 => "Variable2",
                      :hash1 => {:key1 => "Value1", :key2 => "Value2"},
                      :hash2 => {:key1 => "Value1", :key2 => "Value2"},
      }
      @check = Rasca::Check.new("Test","test/etc_default",true,true)
      @check.debug=true
    end

    should 'have default data_dir' do
      assert_equal "/var/lib/modularit/data", @check.data_dir
    end

    should 'be able to change default data_dir' do
      @check.data_dir="test_data"
      assert_equal "test_data", @check.data_dir
    end

    should "correctly read persistent data" do
      @check.data_dir="test/test_data"
      assert_equal @data, @check.readData("Test")
    end

    should "correctly write persistent data" do
      @check.data_dir="test/test_data"
      FileUtils.rm_f "test/test_data/TestOut/Data.yml"
      assert_equal true, @check.writeData("TestOut",@data).instance_of?(File)
    end

    should "read data should be equal to written" do
      @check.data_dir="test/test_data"
      assert_equal @data, @check.readData("TestOut")
      FileUtils.rm_f "test/test_data/TestOut/Data.yml"
    end

  end

end
