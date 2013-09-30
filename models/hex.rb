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

  def coordinates
    [x, y]
  end

  def adjacencies
    [1,0,-1].permutation(2).map{|i,j| [x+i, y+j] }
  end
  
  def adjacent?(hex)
    adjacencies.include?(hex.coordinates)
  end
end
