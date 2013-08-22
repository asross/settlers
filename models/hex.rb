class Hex
  attr_accessor :x, :y, :number, :type, :robbed

  def inspect
    "<Hex: #{type} (#{number}) [#{x},#{y}]>"
  end
  
  def initialize(x, y, number, type, robbed=false)
    @x = x
    @y = y
    @number = number
    @type = type
    @robbed = robbed
  end
  
  def adjacent?(hex)
    [1,0,-1].permutation(2).include?([x-hex.x, y-hex.y])
  end
end
