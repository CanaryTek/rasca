require "helper"

class TestUsesObjects < Test::Unit::TestCase

  context "UsesObjects module" do
    setup do
      @check = Rasca::Check.new("Test","test/etc_default",true,true)
      @check.debug=true
    end

    should 'have default object_dir' do
      assert_equal "/var/lib/modularit/obj", @check.object_dir
    end

    should 'be able to change default object_dir' do
      @check.object_dir="test_objects"
      assert_equal "test_objects", @check.object_dir
    end

    should "correctly initialize objects" do
      @objects={ :section1 => "Section1", :section2 => "Section2", :local => "Local",
                      :hash1 => {:key2 => "Value2_new", :key3 => "Value3"},
                      :hash2 => {:key1 => "Value1"},
      }
      @check.object_dir="test/test_objects"
      @check.readObjects("Test")
      assert_equal @objects, @check.objects
    end

  end

end
