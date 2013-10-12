class Player < Catan
  RESOURCE_CARDS = %w(brick wood sheep wheat ore)
  attr_accessor *RESOURCE_CARDS, :color, :points, :board, :development_cards
  
  def initialize(board, color)
    @board = board
    @color = color
    @points = 0
    @development_cards = []
    RESOURCE_CARDS.each{|r| send("#{r}=", 0) }
  end

  def inspect
    "<Player: #{color}>"
  end
  
  def increment(resource, n)
    error 'Bad resource card' unless RESOURCE_CARDS.include?(resource)
    send("#{resource}=", send(resource)+n)
  end

  def resource_cards
    RESOURCE_CARDS.map{|r| [r]*send(r)}.flatten
  end

  def steal_from(other)
    error 'Cannot steal from yourself' if other == self
    if resource = other.resource_cards.shuffle.first
      self.increment(resource, 1)
      other.increment(resource, -1)
    end
  end

  def settlements
    board.settlements.select{|s| s.size == 1 && s.color == color }
  end

  def cities
    board.settlements.select{|s| s.size == 2 && s.color == color }
  end

  def roads
    board.roads.select{|r| r.color == color }
  end

  def trade_in_ratio_for(resource)
    n = 4
    (settlements + cities).each do |settlement|
      settlement.hexes.each do |hex|
        next unless hex.port_borders?(settlement)
        next unless (m = hex.port_accepts?(resource))
        n = [n,m].min
      end
    end
    n
  end

  def trade_in(resource1, resource2)
    error 'Bad resource card' unless [resource1, resource2].all?{|r| RESOURCE_CARDS.include?(r) }
    n = trade_in_ratio_for(resource1)
    error 'Not enough resources to trade' unless send(resource1) >= n
    increment(resource1, -n)
    increment(resource2, 1)
  end

  def build_settlement(hex1, hex2, hex3, turn1=false, turn2=false)
    error 'Already built 5 settlements' if settlements.count >= 5
    error 'Too close to existing settlement/city' if board.settlement_near?(hex1, hex2, hex3)
    error 'Hexes are not adjacent' unless [hex1, hex2, hex3].combination(2).all?{|h1, h2| h1.adjacent?(h2) }
    unless turn1 || turn2
      error 'No road leading to settlement' unless board.road_to?(hex1, hex2, hex3, color)
      error 'Not enough resources to build settlement' unless [sheep, wheat, brick, wood].all?{|r| r >= 1}
    end
    board.settlements << Settlement.new(hex1, hex2, hex3, self)
    @points += 1
    if turn2
      [hex1, hex2, hex3].each do |hex|
        increment(hex.type, 1) if RESOURCE_CARDS.include?(hex.type)
      end
    elsif !turn1
      @sheep -= 1
      @wheat -= 1
      @brick -= 1
      @wood -= 1
    end
  end

  def build_road(hex1, hex2, road_is_free=false)
    error 'Already built 15 roads' if roads.count >= 15
    error 'Road not buildable there' unless board.road_buildable_at?(hex1, hex2, color)
    error 'Not enough resources to build road' unless road_is_free || (wood >= 1 && brick >= 1)
    board.roads << Road.new(hex1, hex2, color)
    board.check_for_longest_road(self)
    unless road_is_free
      @brick -= 1
      @wood -= 1
    end
  end

  def build_city(hex1, hex2, hex3)
    error 'No settlement at location' unless board.settlement_at?(hex1, hex2, hex3, color, true)
    error 'Not enough resources to build city' unless ore >= 3 && wheat >= 2
    board.settlement_at(hex1, hex2, hex3).size = 2
    @points += 1
    @wheat -= 2
    @ore -= 3
  end
end
