class Road
  attr_accessor :hexes, :color

  def initialize(hex1, hex2, color)
    @hexes = [hex1, hex2]
    @color = color
  end
end
