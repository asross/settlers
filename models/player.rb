class Player
  attr_accessor :sheep, :wheat, :brick, :wood, :ore, :color, :points, :n_settlements, :n_roads
  
  def initialize(board, color)
    @board = board
    @color = color
    @points = 0
    @n_settlements = 0
    @n_roads = 0
    @sheep = 0
    @wheat = 0
    @brick = 0
    @wood = 0
    @ore = 0
  end

  def error(msg)
    raise msg
  end
  
  def increment(resource, n)
    send("#{resource}=", send(resource)+n)
  end

  def trade_in(n, resource1, resource2)
    error 'Not enough resources to trade' unless send(resource1) >= n
    increment(resource1, -n)
    increment(resource2, 1)
  end

  def build_settlement(hex1, hex2, hex3, startTurn=false)
    error 'Already built 5 settlements' if n_settlements >= 5
    error 'Too close to existing settlement/city' if board.settlement_near?(hex1, hex2, hex3)
    unless startTurn
      error 'No road leading to settlement' unless board.road_to?(hex1, hex2, hex3, color)
      error 'Not enough resources to build settlement' unless [sheep, wheat, brick, wood].all?{|r| r >= 1}
    end
    [sheep, wheat, brick, wood].each{|r| r -= 1 }
    settlement = Settlement.new(hex1, hex2, hex3, self)
    board.settlements << settlement
    n_settlements += 1
    points += 1
  end

  def build_road(hex1, hex2, startTurn=false)
    error 'Already built 15 roads' if n_roads >= 15
    error 'Road not buildable there' unless board.road_buildable_at?(hex1, hex2. color)
    error 'Not enough resources to build road' unless startTurn || (wood >= 1 && brick >= 1)
    road = Road.new(hex1, hex2, color)
    board.roads << road
    n_roads += 1
    board.check_for_longest_road(self)
  end

  def build_city(hex1, hex2, hex3)
    error 'No settlement at location' unless board.settlement_at?(hex1, hex2, hex3, color=color, just_settlements=true)
    error 'Not enough resources to build city' unless ore >= 3 && wheat >= 2
    ore -= 3
    wheat -= 2
    board.upgrade_settlement(hex1, hex2, hex3)
    n_settlements -= 1
    points += 1
  end
end
