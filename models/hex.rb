class Hex < Catan
  attr_accessor :x, :y, :number, :type, :robbed, :port_type, :port_direction

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

  def directions
    Hash[%w(botright topright bottom top botleft topleft).zip(adjacencies)]
  end

  def port_borders?(settlement)
    return false unless port_direction
    return false unless settlement.vertex.include?(coordinates)
    settlement.vertex.include?(directions[port_direction])
  end

  def port_accepts?(resource)
    return 3 if port_type == '3:1'
    return 2 if port_type == resource
    false
  end
end
