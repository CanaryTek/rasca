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
      FileUtils.rm_f "test/test_data/TestOut/Data.json"
      @check.persist=@data
      assert_equal true, @check.writeData("TestOut").instance_of?(File)
    end

    should "read data should be equal to written" do
      @check.data_dir="test/test_data"
      assert_equal @data, @check.readData("TestOut")
      FileUtils.rm_f "test/test_data/TestOut/Data.json"
    end

    should "timestamp should be equal to the one written (first time)" do
      @check.data_dir="test/test_data"
      tstamp1=Time.now.to_i
      @check.persist[:tstamp]=tstamp1
      @check.writeData("TestOut")
      @check.readData("TestOut")
      assert_equal tstamp1,@check.persist[:tstamp]
    end

    should "timestamp should be equal to the one written (second time)" do
      @check.data_dir="test/test_data"
      tstamp2=Time.now.to_i
      @check.persist[:tstamp]=tstamp2
      @check.writeData("TestOut")
      @check.readData("TestOut")
      assert_equal tstamp2,@check.persist[:tstamp]
    end

  end

end
