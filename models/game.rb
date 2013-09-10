class Game < Catan
  STATES = [:preroll, :postroll, :robbing1, :robbing2, :start_turn1, :start_turn2]
  ACTIONS = %w(roll build_settlement build_city build_road trade_in pass_turn move_robber rob_player)
  attr_accessor :messages, :board, :players, :turn, :last_roll
  attr_reader :state
  
  def initialize(board=nil, players=nil)
    @board = board || Board.create
    @players = players || %w(aqua deeppink gold lightcoral thistle).shuffle[0..2].map do |color|
      Player.new(@board, color)
    end
    @turn = 0
    @messages = []
    @state = :start_turn1
  end

  def round
    turn / players.size
  end

  def active_player
    players[turn % players.size]
  end

  def available_actions(player)
    return [] unless player == active_player  # eventually, could "accept trade request"
    
    case state
    when :preroll     then %w(roll)
    when :postroll    then %w(build_settlement build_city build_road trade_in pass_turn)
    when :robbing1    then %w(move_robber)
    when :robbing2    then %w(rob_player)
    when :start_turn1 then %w(build_settlement)
    when :start_turn2 then %w(build_road)
    else []
    end
  end

  def perform_action(player, action, args=[])
    unless available_actions(player).include?(action)
      error "#{player.color} cannot perform #{action} at this time"
    end
    send(action, *args)
  end

  def state=(s)
    raise ArgumentError, "invalid state #{s}" unless STATES.include?(s)
    @state = s
  end


  private

  def random_dieroll
    2 +rand(6) + rand(6)
  end

  def roll
    @last_roll = random_dieroll
    @board.rolled(@last_roll)
    if @last_roll == 7
      self.state = :robbing1
    else
      self.state = :postroll
    end
  end

  def rob_player(color)
    robbee = @robbable.detect{|p| p.color == color}
    error "invalid selection #{color} (must pick one of #{@robbable.join(', ')})" unless robbee
    active_player.steal_from(robbee)
    self.state = :postroll
  end

  def move_robber(v)
    robbable = @board.move_robber_to(*v, active_player)
    case robbable.size
    when 0
      self.state = :postroll
    when 1
      active_player.steal_from(robbable.first)
      self.state = :postroll
    else
      @robbable = robbable
      self.state = :robbing2
    end
  end

  def build_road(v1, v2)
    active_player.build_road(h(*v1), h(*v2), state == :start_turn2)

    if state == :start_turn2
      @turn += 1
      self.state = (round >= 2) ? :preroll : :start_turn1
    end
  end

  def build_city(v1, v2, v3)
    active_player.build_city(h(*v1), h(*v2), h(*v3))
  end

  def build_settlement(v1, v2, v3)
    active_player.build_settlement(h(*v1), h(*v2), h(*v3), round == 0, round == 1)

    self.state = :start_turn2 if state == :start_turn1
  end

  def trade_in(r1, r2)
    active_player.trade_in(r1, r2, 4) # TODO: make this dependent on ports
  end

  def pass_turn
    @turn += 1
    self.state = :preroll
  end

  def h(x, y)
    @board.hexes[x][y]
  end
end
