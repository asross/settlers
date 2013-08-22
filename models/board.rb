class Board
  TOKENS = [5, 2, 6, 3, 8, 10, 9, 12, 11, 4, 8, 10, 9, 4, 5, 6, 3, 11]
  HEX_TYPES = %w(ore)*3 + %w(brick)*3 + %w(sheep)*4 + %w(wheat)*4 + %w(wood)*4 + %w(desert)
  attr_accessor :settlements, :roads, :hexes, :robbed_coords, :longest_road_player, :longest_road_length, :size

  def self.create(side_length=3)
    hexes = []
    tokens = TOKENS.dup.cycle
    hex_types = HEX_TYPES.dup.shuffle.cycle

    size = side_length*2+1
    size.times do |i|
      hex_row = []
      size.times do |j|
        if (side_length+1..side_length*3-1).include?(i+j) && ([0,size-1] & [i,j]).size == 0
          type = hex_types.next
          token = (tokens.next unless type == 'desert')
        else
          type = 'water'
          token = nil
        end
        hex_row << Hex.new(i, j, token, type, (type == 'desert'))
      end
      hexes << hex_row
    end
    
    new(hexes, size)
  end
  
  def initialize(hexes, size)
    @hexes = hexes
    @size = size
    @robbed_hex = hexes.flatten.select{|h| h.type == 'desert'}.first
    @settlements = []
    @roads = []
    @longest_road_player = nil
    @longest_road_length = 0
  end
  
  def rolled(roll)
    settlements.each{|s| s.rolled(roll) }
  end
  
  def move_robber_to(hex, player)
    robbed_hex.robbed = false
    robbed_hex = hex
    robbed_hex.robbed = true
    robbable = []
    for s in settlements
      if s.hexes.include?(hex) && s.player != player && !robbable.include?(s.player)
        robbable << s.player
      end
    end
    robbable
  end
  
  def hexes_adjacent_to(hex1, hex2=nil) # returns hexes adjacent to both hex1 and hex2
    # assume hex1 and hex2 are adjacent. could put in a safeguard easily with hex1.adjacent?(hex2)

    if hex2.nil?
      if hex.y > 0 and hex.x > 0
        return [@hexes[hex1.x][hex1.y+1], @hexes[hex1.x][hex1.y-1], @hexes[hex1.x+1][hex1.y], @hexes[hex1.x+1][hex1.y-1], @hexes[hex1.x-1][hex1.y], @hexes[hex1.x-1][hex1.y+1]]
      elsif hex.y == 0 and hex.x > 0
        return [@hexes[hex1.x][hex1.y+1], @hexes[hex1.x+1][hex1.y], @hexes[hex1.x-1][hex1.y], @hexes[hex1.x-1][hex1.y+1]]
      elsif hex.x == y and hex.y > 0
        return [@hexes[hex1.x][hex1.y+1], @hexes[hex1.x][hex1.y-1], @hexes[hex1.x+1][hex1.y], @hexes[hex1.x+1][hex1.y-1]]
      else
        return [@hexes[hex1.x][hex1.y+1], @hexes[hex1.x+1][hex1.y]]
      end
    else
      if hex1.y == hex2.y
        if hex1.y == 0
          return [nil, @hexes[[hex1.x,hex2.x].min][hex1.y+1]]
        else
          return [@hexes[[hex1.x,hex2.x].max][hex1.y-1], @hexes[[hex1.x,hex2.x].min][hex1.y+1]]
        end
      elsif hex1.x == hex2.x
        if hex1.x == 0
          return [nil, @hexes[hex1.x+1][[hex1.y,hex2.y].min]]
        else
          return [@hexes[hex1.x-1][[hex1.y,hex2.y].max], @hexes[hex1.x+1][[hex1.y,hex2.y].min]]
        end
      else
        return [@hexes[[hex1.x,hex2.x].max][[hex1.y,hex2.y].max], @hexes[[hex1.x,hex2.x].min][[hex1.y,hex2.y].min]]
      end
    end
  end
  
  def road_to?(hex1, hex2, hex3, color) 
    for road in roads
      r1 = road.hexes - [hex1, hex2] # true if there's a road between hex1 and hex2
      r2 = road.hexes - [hex1, hex3] # true if there's a road between hex1 and hex3
      r3 = road.hexes == [hex2, hex3] # true if there's a road between hex2 and hex3
      next unless r1 || r2 || r3
      return true if road.color == color
    end
    false
  end
  
  def roads_to(hex1, hex2, hex3, color)
    result = []
    # if there's a settlement not of our color, longest road is blocked so don't return anything
    if settlement_at?(hex1, hex2, hex3) and !settlement_at?(hex1, hex2, hex3, color=color)
      return result
    end
    for road in roads
      r1 = [hex1, hex2] & road.hexes == [hex1, hex2] # true if there's a road between hex1 and hex2
      r2 = [hex1, hex3] & road.hexes == [hex1, hex3] # true if there's a road between hex1 and hex3
      r3 = [hex2, hex3] & road.hexes == [hex2, hex3] # true if there's a road between hex2 and hex3
      if r1 or (r2 or r3)
        if road.color == color
          result << road
        end
      end
    end
    return result
  end
  
  def settlement_at?(hex1, hex2, hex3, color=nil, just_settlements=false)
    result = false
    for city in cities
      if [hex1, hex2, hex3] & city.hexes == [hex1, hex2, hex3]
        if color.nil? or city.color == color
          if !just_settlements or city.size == 1
            result = true
          end
        end
      end
    end
    return result
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
    if settlement_at?(hex1, hex2, hex3s[0], color=color) or settlement_at?(hex1, hex2, hex3s[1], color=color)
      #puts "Can build road because of a nearby settlement! Woohoo!"
      return true
    end   
    # if there's a road of our color leading to this one (not blocked by a settlement), return true
    if (road_to?(hex1, hex2, hex3s[0], color=color) and !settlement_at?(hex1, hex2, hex3s[0])) or (road_to?(hex1, hex2, hex3s[1], color=color) and !settlement_at?(hex1, hex2, hex3s[1]))
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
    for city in cities
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


