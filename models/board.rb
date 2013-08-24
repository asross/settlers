class Board
  TOKENS = [5, 2, 6, 3, 8, 10, 9, 12, 11, 4, 8, 10, 9, 4, 5, 6, 3, 11]
  HEX_TYPES = %w(ore)*3 + %w(brick)*3 + %w(sheep)*4 + %w(wheat)*4 + %w(wood)*4 + %w(desert)
  attr_accessor :settlements, :roads, :hexes, :robbed_hex, :longest_road_player, :longest_road_length, :side_length

  def self.on_island?(i,j,l)
    return false unless (l+1..l*3-1).include?(i+j)
    return false unless ([0,l*2] & [i,j]).size == 0
    true
  end

  def self.create(side_length=3)
    tokens = TOKENS.dup.cycle
    hex_types = HEX_TYPES.dup.shuffle.cycle

    hexes = \
    0.upto(side_length*2).map do |i|
      0.upto(side_length*2).map do |j|
        type  = (on_island?(i, j, side_length) ? hex_types.next : 'water')
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
    @robbed_hex = hexes.flatten.select{|h| h.type == 'desert'}.first
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
    settlements.select{|s| s.hexes - [hex1, hex2, hex3] == []}.first
  end
  
  def settlement_at?(hex1, hex2, hex3, color=nil, just_settlements=false)
    settlement = settlement_at(hex1, hex2, hex3)
    return false unless settlement
    return false if color && color != settlement.color
    return false if just_settlements && settlement.size != 1
    true
  end
  
  def road_buildable_at?(hex1, hex2, color)
    # if there's already a road at h1, h2, return false
    for road in roads
      if [hex1, hex2] & road.hexes == [hex1, hex2]
        #puts "Oops! Already a road here."
        return false
      end
    end
    # find the adjacent hexes
    hex3s = hexes_adjacent_to(hex1, hex2)
    # if there's a settlement nearby, return true
    if settlement_at?(hex1, hex2, hex3s[0], color) or settlement_at?(hex1, hex2, hex3s[1], color)
      #puts "Can build road because of a nearby settlement! Woohoo!"
      return true
    end   
    # if there's a road of our color leading to this one (not blocked by a settlement), return true
    if (road_to?(hex1, hex2, hex3s[0], color) and !settlement_at?(hex1, hex2, hex3s[0])) or (road_to?(hex1, hex2, hex3s[1], color) and !settlement_at?(hex1, hex2, hex3s[1]))
      #puts "Can build road because of a leading road. Woohoo!"
      return true
    end
  end
  
  def settlement_near?(hex1, hex2, hex3)
    hex12s = hexes_adjacent_to(hex1, hex2)
    hex13s = hexes_adjacent_to(hex1, hex3)
    hex23s = hexes_adjacent_to(hex2, hex3)
    if settlement_at?(hex1, hex2, hex12s[0]) or settlement_at?(hex1, hex2, hex12s[1])
      return true
    elsif settlement_at?(hex1, hex3, hex13s[0]) or settlement_at?(hex1, hex3, hex13s[1])
      return true
    elsif settlement_at?(hex2, hex3, hex23s[0]) or settlement_at?(hex2, hex3, hex23s[1])
      return true
    else
      return false
    end
  end
  
  def upgrade_settlement(hex1, hex2, hex3)
    for city in settlements
      if [hex1, hex2, hex3] & city.hexes == [hex1, hex2, hex3]
        # could assert city.size = 1 here
        city.size = 2   # if ruby really works by reference, this should stick.
      end
    end
  end
  
  
  def check_for_longest_road(player)
    #puts "entering check_for_longest_road"
    # first define recursive function used to find length of road chain
    def find_length(rhode, color, previous_roads=[rhode])
      #puts "entering find_length"
      adjHexes = hexes_adjacent_to(rhode.hexes[0], rhode.hexes[1])
      rhodes = roads_to(rhode.hexes[0], rhode.hexes[1], adjHexes[0], color)
      rhodes.concat(roads_to(rhode.hexes[0], rhode.hexes[1], adjHexes[1], color))
      #puts "rhodes.empty? is #{rhodes.empty?}"
      new_roads = []
      for rowed in rhodes
        if ([rowed] & previous_roads).empty?
          new_roads << rowed
        end
      end
      #puts "new_roads.empty? is #{new_roads.empty?}"
      result = 0
      for rowed in new_roads
        temp_result = 1 + find_length(rowed, color, previous_roads + [rowed])
        result = [result, temp_result].max
      end
      return result
    end
    # now call that recursive function for all the player's roads.
    color = player.color
    length = 0
    for road in @roads
      if road.color == color
        l = find_length(road, color) + 1
        #puts "l is #{l}"
        if l > length
          length = l
        end
      end
    end
    # if its result is longer than 5 and longer than the current longest road, give our player longest road
    if length >= 5 and length > @longest_road_length
      if @longest_road_player != player
        if !@longest_road_player.nil?
          @longest_road_player.points -= 2
        end
        player.points += 2
        @longest_road_player = player
        puts "\n!!!!! Longest road obtained by #{color} !!!!!\n"
      end
      @longest_road_length = length
    end
  end
end


