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
    case y
    when hex.y     then (x - hex.x).abs == 1
    when hex.y + 1 then [hex.x, hex.x - 1].include? x
    when hex.y - 1 then [hex.x, hex.x + 1].include? x
    else false
    end
  end
end
