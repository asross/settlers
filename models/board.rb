class Board
  NUMBER_TOKENS = [5, 2, 6, 3, 8, 10, 9, 12, 11, 4, 8, 10, 9, 4, 5, 6, 3, 11]
  HEX_TYPES = %w(ore brick)*3 + %w(sheep wheat wood)*4 + %w(desert)
  attr_accessor :settlements, :roads, :hexes, :robbed_hex, :longest_road_player, :longest_road_length, :side_length

  def self.on_island?(i,j,l)
    return false unless (l+1..l*3-1).include?(i+j)
    return false unless ([0,l*2] & [i,j]).size == 0
    true
  end

  def self.create(side_length=3)
    types = HEX_TYPES.dup.shuffle.cycle
    tokens = NUMBER_TOKENS.dup.cycle

    hexes = \
    0.upto(side_length*2).map do |i|
      0.upto(side_length*2).map do |j|
        type  = (on_island?(i, j, side_length) ? types.next : 'water')
        token = (tokens.next unless %w(water desert).include?(type))
        Hex.new(i, j, token, type)
      end
    end

    new(hexes, side_length)
  end

  def error(msg)
    raise msg
  end

  def initialize(hexes, side_length)
    @hexes = hexes
    @side_length = side_length
    @robbed_hex = hexes.flatten.detect{|h| h.type == 'desert'}
    @robbed_hex.robbed = true
    @settlements = []
    @roads = []
    @longest_road_player = nil
    @longest_road_length = 0
  end

  def rolled(roll)
    settlements.each{|s| s.rolled(roll) }
  end

  def move_robber_to(x, y, player)
    error 'invalid robber location' unless hexes[x] && hex = hexes[x][y]
    error 'cannot pick same location' if hex == @robbed_hex
    @robbed_hex.robbed = false
    @robbed_hex = hex
    @robbed_hex.robbed = true
    robbable = []
    for s in settlements
      next unless s.hexes.include?(hex)
      next if s.player == player
      next if robbable.include? player
      robbable << s.player
    end
    robbable
  end

  def size
    side_length*2 + 1
  end

  def hexes_adjacent_to(hex1, hex2=nil)
    positions = hex1.adjacencies
    positions = hex2.adjacencies & positions if hex2
    positions.reject{|x,y| x >= size || y >= size}.map{|x,y| hexes[x][y] }
  end

  def road_to?(hex1, hex2, hex3, color)
    roads_to(hex1, hex2, hex3, color).any?
  end

  def roads_to(hex1, hex2, hex3, color)
    result = []
    for road in roads
      next unless road.color == color
      next unless [hex1, hex2, hex3].permutation(2).include?(road.hexes)
      result << road
    end
    result
  end

  def settlement_at(hex1, hex2, hex3)
    settlements.detect{|s| s.hexes - [hex1, hex2, hex3] == []}
  end

  def settlement_at?(hex1, hex2, hex3, color=nil, just_settlements=false)
    settlement = settlement_at(hex1, hex2, hex3)
    return false unless settlement
    return false if color && color != settlement.color
    return false if just_settlements && settlement.size != 1
    true
  end

  def road_at(hex1, hex2)
    roads.detect{|r| r.hexes - [hex1, hex2] == []}
  end

  def road_buildable_at?(hex1, hex2, color)
    return false if road_at(hex1, hex2)
    for hex in hexes_adjacent_to(hex1, hex2)
      trio = [hex1, hex2, hex]
      return true if settlement_at?(*trio, color)
      return true if road_to?(*trio, color) && !settlement_at?(*trio)
    end
    false
  end

  def settlement_near?(hex1, hex2, hex3)
    [hex1, hex2, hex3].combination(2).each do |h1, h2|
      return true if hexes_adjacent_to(h1,h2).any?{|h| settlement_at?(h,h1,h2) }
    end
    false
  end

  def longest_road_length(color)
    roads.select{|r| r.color == color}.map{|r| longest_path_from(r)}.max
  end

  def longest_path_from(road, visited=[road], last_vertex=[])
    successors = []

    hexes_adjacent_to(*road.hexes).each do |hex|
      vertex = road.hexes + [hex]
      settle = settlement_at(*vertex)

      next if settle && settle.color != road.color
      next if vertex - last_vertex == []

      roads_to(*vertex, road.color).each do |r|
        next if visited.include?(r)
        successors << [r,vertex]
      end
    end

    return visited.length unless successors.any?

    successors.map do |r,vertex|
      longest_path_from(r, visited+[r], vertex)
    end.max
  end


  def check_for_longest_road(player)
    length = longest_road_length(player.color)

    if length >= 5 and length > @longest_road_length
      unless @longest_road_player == player
        @longest_road_player.points -= 2 if @longest_road_player
        @longest_road_player = player
        @longest_road_player.points += 2
      end
      @longest_road_length = length
    end
  end
end
