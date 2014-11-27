class Road
  attr_accessor :hexes, :color

  def initialize(hex1, hex2, color)
    @hexes = [hex1, hex2]
    @color = color
  end

  def as_json
    {
      hexes: hexes.map(&:as_json),
      color: color
    }
  end

  def to_s
    "#<Road (#{color}) #{[@hexes[0].x, @hexes[0].y]} to #{[@hexes[1].x, @hexes[1].y]}>" 
  end
end
