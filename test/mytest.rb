class Parent
  attr_accessor :name, :son

  def initialize(name)
    @name=name
    @son=Son.new(self,"#{@name}Son")
  end
end

class Son
  attr_accessor :name, :parent

  def initialize(parent,name)
    @parent=parent
    @name=name
  end
end
