require "helper"

class TestConfigurable < Test::Unit::TestCase

  context "Configurable module" do
    setup do
      @check = Rasca::Check.new("Test")
    end

    should 'have default config_dir' do
      assert_equal "/etc/modularit", @check.config_dir
    end

    should 'be able to change default config_dir' do
      @check.config_dir="local_config_dir"
      assert_equal "local_config_dir", @check.config_dir
    end

    should 'raise exception if config file does not exist' do
      @check.config_dir="local_config_dir"
      assert_raise RuntimeError do
        @check.readConfig
      end
    end

  end

  context "readConfig method" do
    setup do
      @config_hash={ :general => "General", :section1 => "Section1", :section2 => "Section2", :local => "Local",
                      :hash1 => {:key1 => "Section1", :key2 => "Value2_new", :key3 => "Value3"},
                      :hash2 => {:key1 => "Value1"},
      }
      @check = Rasca::Check.new("Test")
      @check.config_dir="test/test_config"
      @check.readConfig
    end

    should 'apply config precedence correctly' do
      assert_equal "General",@check.config_values[:general]
      assert_equal "Section1",@check.config_values[:section1]
      assert_equal "Section2",@check.config_values[:section2]
      assert_equal "Local",@check.config_values[:local]
    end

    should 'create a correct config hash' do
      assert_equal @config_hash,@check.config_values
    end

  end

end
