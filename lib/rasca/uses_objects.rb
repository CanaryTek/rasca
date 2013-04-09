module Rasca
require 'yaml'
#require 'json'

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
      # Read all JSON files on section
      Dir.glob(section_dir+"/*.json") do |file|
        obj=JSON.parse(File.read(file),:symbolize_names => true) unless File.basename(file) == "Local.json"
        @objects.merge!(obj) if obj
      end
      # Read all YAML files on section, except Local.obj
      Dir.glob(section_dir+"/*.obj") do |file|
        obj=YAML.load(File.open(file)) unless File.basename(file) == "Local.obj"
        @objects.merge!(obj) if obj
      end
    end
    # Read local JSON files
    if File.exists?section_dir+"/Local.json"
      obj=JSON.parse(File.read(section_dir+"/Local.json"),:symbolize_names => true)
      @objects.merge!(obj) if obj
    end
    # Read local YAML file
    if File.exists?section_dir+"/Local.obj"
      obj=YAML.load(File.open(section_dir+"/Local.obj"))
      @objects.merge!(obj) if obj
    end
    puts "Objects:" if @debug
    puts YAML.dump(@objects) if @debug
    @objects
  end

end

end # module Rasca