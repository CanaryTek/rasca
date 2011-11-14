module Rasca
require 'yaml'
require 'deep_merge'

# Default config dir
DEFAULT_CONFIG_DIR = "/etc/modularit"

# Configurable
# Can have  hierarchy of configuration files
module Configurable
  attr_accessor :config_dir, :config_values

  # Constructor: Read configuration
  def initialize(config_dir=nil)

    @config_dir = DEFAULT_CONFIG_DIR

    # If config dir given, readConfig now from that dir
    if (config_dir)
      @config_dir=config_dir
    end
    readConfig

  end

  # Read configuration
  # The configuration will be read in the following order:
  # 1. General config 
  # 2. Section config (the one specified in the parameter section)
  # 3. Local config (Local configuration for this host)
  # This way checks can override global config, and we can locally override config in a machine with localconfig
  def readConfig(section=@name)
    puts "Using config dir: #{@config_dir}" if @debug
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
    
    # Check that we have at least the mandatory Rasca options
    unless @config_values.has_key? :hostname
      raise "ERROR: No :hostname config entry found"
    end
    unless @config_values.has_key? :notify_methods
      raise "ERROR: No :notify_methods config entry found"
    end
  end

  

end

end # module Rasca
