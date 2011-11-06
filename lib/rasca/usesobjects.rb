module Rasca

module UsesObjects
  attr_accessor :object_dir

  # Read configuration
  # The configuration will be read in the following order:
  # 1. General config 
  # 2. Section config (the one specified in the parameter section)
  # 3. Local config (Local configuration for this host)
  # This way checks can override global config, and we can locally override config in a machine with localconfig
  def readObjects

  end

  def initialize
    @object_dir = DEFAULT_OBJECTS_DIR
  end

end

end # module Rasca
