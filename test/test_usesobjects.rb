require "helper"

class TestUsesObjects < Test::Unit::TestCase

  context "UsesObjects module" do
    setup do
      @check = Rasca::Check.new("Test")
    end

    should 'have default object_dir' do
      assert_equal "/var/lib/modularit/obj", @check.object_dir
    end

    should 'be able to change default object_dir' do
      @check.object_dir="local_config_dir"
      assert_equal "local_config_dir", @check.object_dir
    end


  end

end
