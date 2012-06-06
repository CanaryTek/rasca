require "helper"

class TestActionDuplicity < Test::Unit::TestCase

  context "An instance of ActionDuplicity" do
    setup do
      @action=Rasca::ActionDuplicity.new("CheckDuplicity","test/etc",true,true)
      @action.testing=false
      @action.debug=true
      @action.object_dir="test/objects"
    end

    should 'return false if nonexistent volume' do
      assert_equal false,@action.run("nonexistent","inc")
    end

    should 'return true if correct volume' do
      assert_equal true,@action.run("test/etc","inc")
    end

  end

end