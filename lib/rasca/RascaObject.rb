module Rasca

# This class defines a top level Rasca object
class RascaObject
  include Configurable
  include UsesObjects
  include UsesPersistentData
  include Notifies

  attr_accessor :name, :debug, :verbose, :hostname, :testing

  # Initialize the object with the given name. The initial status will be UNKNOWN
  def initialize(name,config_dir=nil,debug=false,verbose=false,read_objects=true)
    # testing=true is used for unit testing.
    # normal whe use it to use test input instead of the real system command
    @testing=false

    # Set name. This needs to be first
    @name=name
    # Set initial status
    @status="UNKNOWN"
    # Defaults for debug and verbose
    @debug=debug
    @verbose=verbose
    @verbose=true if @debug
    # Print_only
    @print_only=false

    # Config_values
    @config_values=Hash.new

    # Persistent data
    @persist=Hash.new

    # Initialization of each module (Ruby's super will only call last included Module's constructor)
    Configurable.instance_method(:initialize).bind(self).call(config_dir)
    Notifies.instance_method(:initialize).bind(self).call

    # Set client hostname
    puts YAML.dump(@config_values) if @debug
    @hostname=@config_values[:hostname]

    # Initializes UsesObjects
    @object_dir=@config_values.has_key?(:object_dir) ? @config_values[:object_dir] : DEFAULT_OBJECTS_DIR
    UsesObjects.instance_method(:initialize).bind(self).call(@object_dir)

    # Initializes UsesPersistentData
    @data_dir=@config_values.has_key?(:data_dir) ? @config_values[:data_dir] : DEFAULT_DATA_DIR
    UsesPersistentData.instance_method(:initialize).bind(self).call(@data_dir)

    # Initialize notificaton object
    if @config_values.has_key? :notify_methods
      @notify_methods=@config_values[:notify_methods]
    else
      @notify_methods={ :print => nil}
    end
  end
  # Cleanup. Clean up if needed
  def cleanup
    true
  end

  # Info. Print information about the check
  # - What it does
  # - The object format
  # - Optionaly what to do to correct problems
  def info
    %[
== Description

IF YOU SEE THIS IN A REAL OOBJECT, YOU NEED TO REDEFINE info() METHOD

This check does nothing. It's used as a base class for "real" checks

== Parameters in config file

  :none: It doesn't use any additional parameter

== Objects format

  :none:
    :option1: 
]
  end
end

end # module Rasca
