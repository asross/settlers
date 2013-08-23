class Settlement
  attr_accessor :size, :color, :hexes, :player
  
  def initialize(hex1, hex2, hex3, player)
    @hexes = [hex1, hex2, hex3]
    @player = player
    @size = 1
    @color = player.color
  end
  
  def rolled(roll)
    for hex in hexes
      next if hex.robbed
      next if ['water', 'desert'].include?(hex.type)
      next if hex.number != roll
      player.increment(hex.type, 1)
    end
  end
end
