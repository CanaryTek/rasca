module Rasca
require 'yaml'
require 'deep_merge'

# Default objects dir FIXME: This should be really in the config file
DEFAULT_OBJECTS_DIR = "/var/lib/modularit/obj"

module UsesObjects
  attr_accessor :object_dir, :objects

  def initialize(object_dir)
    @object_dir = object_dir
  end

  # Read objects
  # The configuration will be read in the following order:
  # 1. General config 
  # 2. Section objects
  # 3. Local objects
  # This way checks can override global config, and we can locally override config in a machine with localconfig
  def readObjects(section)
    
    puts "Using objects dir: #{@object_dir}" if @debug
    section_dir=@object_dir+"/"+section
    @objects=Hash.new
    # Read specific config
    if File.directory?section_dir
      puts "Found section: "+section_dir if @debug
      # Read all files on section, except Local.cfg      
      Dir.glob(section_dir+"/*.obj") do |file|
        @objects.deep_merge!(YAML.load(File.open(file))) unless file == "Local.obj"
      end
    end
    # Read local config Local.cfg
    if File.exists?section_dir+"/Local.obj"
      @objects.deep_merge!(YAML.load(File.open(section_dir+"/Local.obj")))
    end
  end

end

end # module Rasca
