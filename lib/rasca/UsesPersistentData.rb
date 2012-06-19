module Rasca
require 'yaml'
require 'fileutils'

# Default objects dir FIXME: This should be really in the config file
DEFAULT_DATA_DIR = "/var/lib/modularit/data"

module UsesPersistentData
  attr_accessor :data_dir, :persist

  def initialize(data_dir=DEFAULT_DATA_DIR)
    @data_dir = data_dir
    @persist = Hash.new
  end

  # Read data
  def readData(section,file="Data")
    @persist=Hash.new
    # Load YAML file
    file_path="#{@data_dir}/#{section}/#{file}.yml"
    puts "Reading persistence file: "+file_path
    puts "Reading persistence file: "+file_path if @debug
    if File.exists?file_path
      @persist=YAML.load(File.open(file_path))
    end
    puts "Data:" if @debug
    puts YAML.dump(@persist) if @debug
    @persist
  end

  # Write data
  def writeData(section,file="Data")
    file_path="#{@data_dir}/#{section}/#{file}.yml"
    # Create dir if needed
    FileUtils.mkdir_p "#{@data_dir}/#{section}" unless File.directory?("#{@data_dir}/#{section}")
    puts "Writing persistence file: "+file_path if @debug
    puts "Data:" if @debug
    puts YAML.dump(@persist) if @debug
    # Write YAML file
    File.open(file_path, 'w') do |out|
      YAML.dump(@persist, out)
    end
  end

end

end # module Rasca
