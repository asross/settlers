class Player < Catan
  RESOURCE_CARDS = %w(sheep wheat brick wood ore)
  attr_accessor *RESOURCE_CARDS, :color, :points, :n_settlements, :n_roads, :board
  
  def initialize(board, color)
    @board = board
    @color = color
    @points = 0
    @n_settlements = 0
    @n_roads = 0
    RESOURCE_CARDS.each{|r| instance_variable_set "@#{r}", 0 }
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

  def trade_in(resource1, resource2, n)
    error 'Bad resource card' unless [resource1, resource2].all?{|r| RESOURCE_CARDS.include?(r) }
    error 'Not enough resources to trade' unless send(resource1) >= n
    increment(resource1, -n)
    increment(resource2, 1)
  end

  def build_settlement(hex1, hex2, hex3, startTurn=false)
    error 'Already built 5 settlements' if n_settlements >= 5
    error 'Too close to existing settlement/city' if board.settlement_near?(hex1, hex2, hex3)
    error 'Hexes are not adjacent' unless [hex1, hex2, hex3].combination(2).all?{|h1, h2| h1.adjacent?(h2) }
    unless startTurn
      error 'No road leading to settlement' unless board.road_to?(hex1, hex2, hex3, color)
      error 'Not enough resources to build settlement' unless [sheep, wheat, brick, wood].all?{|r| r >= 1}
    end
    @sheep -= 1
    @wheat -= 1
    @brick -= 1
    @wood -= 1
    settlement = Settlement.new(hex1, hex2, hex3, self)
    board.settlements << settlement
    @n_settlements += 1
    @points += 1
  end

  def build_road(hex1, hex2, startTurn=false)
    error 'Already built 15 roads' if n_roads >= 15
    error 'Road not buildable there' unless board.road_buildable_at?(hex1, hex2, color)
    error 'Not enough resources to build road' unless startTurn || (wood >= 1 && brick >= 1)
    @brick -= 1
    @wood -= 1
    road = Road.new(hex1, hex2, color)
    board.roads << road
    @n_roads += 1
    board.check_for_longest_road(self)
  end

  def build_city(hex1, hex2, hex3)
    error 'No settlement at location' unless board.settlement_at?(hex1, hex2, hex3, color, true)
    error 'Not enough resources to build city' unless ore >= 3 && wheat >= 2
    @ore -= 3
    @wheat -= 2
    s = board.settlement_at(hex1, hex2, hex3)
    s.size = 2
    @n_settlements -= 1
    @points += 1
  end
end
