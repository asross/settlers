class Board < Catan
  NUMBER_TOKENS = [5, 2, 6, 3, 8, 10, 9, 12, 11, 4, 8, 10, 9, 4, 5, 6, 3, 11]
  HEX_TYPES = %w(ore brick)*3 + %w(sheep wheat wood)*4 + %w(desert)
  PORT_TYPES = %w(brick wood sheep wheat ore) + ['3:1']*4
  CARD_TYPES = %w(knight)*14 + %w(victory_point)*5 + %w(monopoly road_building year_of_plenty)*2
  attr_accessor :settlements, :roads, :hexes, :side_length, :development_cards

  def on_island?(i,j)
    l = side_length
    i.between?(1, l*2-1) &&
      j.between?(1, l*2-1) &&
        (i+j).between?(l+1, l*3-1)
  end

  def sorted_edge_pairs
    @sorted_edge_pairs ||= begin
      edge_pairs = \
        hexes.flatten.select(&:water?).flat_map do |water_hex|
          water_hex.directions.each_with_object([]) do |(dir, (x,y)), pairs|
            if on_island?(x, y)
              pairs << [water_hex, hexes[x][y], dir]
            end
          end
        end

      edge_pairs.sort_by do |pair|
        c = side_length   # effective "center" coordinate
        wx, wy = pair[0].coordinates  # water hex
        lx, ly = pair[1].coordinates  # land hex
        # Angle from center to land hex, plus a tiebreaker term
        Math.atan2(lx-c, ly-c) + 0.00001 * Math.atan2(wx-c, wy-c)
      end
    end
  end

  def initialize(opts={})
    @side_length = opts[:side_length] || 3

    types = HEX_TYPES.dup.shuffle.cycle
    tokens = NUMBER_TOKENS.dup.cycle
    cards = CARD_TYPES.dup.shuffle

    @hexes = \
      0.upto(side_length*2).map do |i|
        0.upto(side_length*2).map do |j|
          if on_island?(i, j)
            type = types.next
            token = (tokens.next unless type == 'desert')
          else
            type = 'water'
            token = nil
          end

          Hex.new(i, j, token, type)
        end
      end

    port_types = PORT_TYPES.dup.shuffle.cycle
    port_intervals = [3,3,4].cycle
    i = 0
    until i >= sorted_edge_pairs.length
      water_hex, land_hex, port_direction = sorted_edge_pairs[i]
      water_hex.port_type = port_types.next
      water_hex.port_direction = port_direction
      i += port_intervals.next
    end

    if desert = @hexes.flatten.detect(&:desert?)
      desert.robbed = true
    end

    @settlements = []
    @roads = []
    @development_cards = cards.map{|c| DevCard.new(c) }
  end

  def rolled(roll)
    settlements.each{|s| s.rolled(roll) }
  end

  def robbed_hex
    @hexes.flatten.detect(&:robbed)
  end

  def move_robber_to(x, y, player)
    error 'invalid robber location' unless hexes[x] && hex = hexes[x][y]
    error 'cannot pick same location' if hex == robbed_hex
    robbed_hex.robbed = false
    hex.robbed = true
    robbable = []
    for s in settlements
      next unless s.hexes.include?(hex)
      next if s.player == player
      next if robbable.include? s.player
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
    roads.select{|r| r.color == color}.map{|r| longest_path_from(r)}.max || 0
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
end
