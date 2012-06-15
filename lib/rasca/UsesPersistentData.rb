module Rasca
require 'yaml'

# Default objects dir FIXME: This should be really in the config file
DEFAULT_DATA_DIR = "/var/lib/modularit/data"

module UsesPersistentData
  attr_accessor :data_dir, :data

  def initialize(data_dir)
    @data_dir = data_dir
  end

  # Read data
  def readData(section)
    puts "Using data dir: #{@data_dir}" if @debug
    section_dir=@data_dir+"/"+section
    puts "Reading section: #{section_dir}" if @debug
    data=Hash.new
    # Load YAML file
    if File.exists?section_dir+"/Data.yml"
      data=YAML.load(File.open(section_dir+"/Data.yml"))
    end
    puts "Data:" if @debug
    puts YAML.dump(@data) if @debug
    data
  end

  # Write data
  def writeData(section,data)
    puts "Using data dir: #{@data_dir}" if @debug
    section_dir=@data_dir+"/"+section
    puts "Writing in section: #{section_dir}" if @debug
    puts "Data:" if @debug
    puts YAML.dump(data) if @debug
    # Write YAML file
    File.open(section_dir+"/Data.yml", 'w') do |out|
      YAML.dump(data, out)
    end
  end

end

end # module Rasca
