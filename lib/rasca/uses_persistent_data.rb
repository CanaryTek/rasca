module Rasca
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
    # Load JSON file
    file_path="#{@data_dir}/#{section}/#{file}.json"
    puts "Reading persistence file: "+file_path if @debug
    if File.exists?file_path
      @persist=JSON.parse(File.read(file_path),:symbolize_names => true)
    end
    puts "Data READ:" if @debug
    puts @persist.inspect if @debug
    @persist
  end

  # Write data
  def writeData(section,file="Data")
    file_path="#{@data_dir}/#{section}/#{file}.json"
    # Create dir if needed
    FileUtils.mkdir_p "#{@data_dir}/#{section}" unless File.directory?("#{@data_dir}/#{section}")
    puts "Writing persistence file: "+file_path if @debug
    puts "Data:" if @debug
    puts JSON.dump(@persist) if @debug
    # Write JSON file
    File.open(file_path, 'w') do |out|
      JSON.dump(@persist, out)
    end
  end

end

end # module Rasca
