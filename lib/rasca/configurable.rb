module Rasca
require 'yaml'
require 'deep_merge'

# Configurable
# Can have  hierarchy of configuration files
module Configurable
  attr_accessor :config_dir, :config_values

  # Constructor: Read configuration
  def initialize

    @config_dir = DEFAULT_CONFIG_DIR

  end

  # Read configuration
  # The configuration will be read in the following order:
  # 1. General config 
  # 2. Section config (the one specified in the parameter section)
  # 3. Local config (Local configuration for this host)
  # This way checks can override global config, and we can locally override config in a machine with localconfig
  def readConfig(section=@name)
    config_file=@config_dir+"/rasca.cfg"
    section_dir=@config_dir+"/"+section
    @config_values=Hash.new
    if File.exists?config_file
      @config_values = YAML.load(File.open(config_file))
    else
      raise "ERROR: config file #{config_file} does not exist"
    end
    # Read specific config
    if File.directory?section_dir
      # Read all files on section, except Local.cfg      
      Dir.glob(section_dir+"/*.cfg") do |file|
        @config_values.deep_merge!(YAML.load(File.open(file))) unless file == "Local.cfg"
      end
      # Read local config Local.cfg
      if File.exists?section_dir+"/Local.cfg"
        @config_values.deep_merge!(YAML.load(File.open(section_dir+"/Local.cfg")))
      end
    end
  end

  

end

end # module Rasca
