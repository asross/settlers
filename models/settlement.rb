class Settlement
  attr_accessor :size, :hexes, :player
  
  def initialize(hex1, hex2, hex3, player)
    @hexes = [hex1, hex2, hex3]
    @player = player
    @size = 1
  end

  def as_json
    {
      hexes: hexes.map(&:as_json),
      color: color,
      size: size
    }
  end

  def color
    player.color
  end
  
  def rolled(roll)
    for hex in hexes
      next if hex.robbed
      next if %w(water desert).include?(hex.type)
      next unless hex.number == roll
      player.increment(hex.type, size)
    end
  end

  def vertex
    hexes.map(&:coordinates)
  end
end
