require "helper"

class TestCheckDuplicity < Test::Unit::TestCase

  context "An instance of CheckDuplicity" do
    setup do
      @action=Rasca::CheckDuplicity.new("CheckDuplicity","test/etc",true,true)
      @action.testing=false
      @action.debug=true
      @action.object_dir="test/objects"
    end

    should 'detect errors on backups' do
      flunk "not done"
    end

  end

end
