class Game < Catan
  STATES = [:preroll, :postroll, :robbing1, :robbing2, :start_turn1, :start_turn2, :road_building1, :road_building2]
  FREE_ROAD_STATES = [:start_turn2, :road_building1, :road_building2]
  DEV_CARD_ACTIONS = %w(monopoly knight year_of_plenty road_building)
  ACTIONS = %w(roll build_settlement build_city build_road buy_development_card trade_in pass_turn move_robber rob_player) + DEV_CARD_ACTIONS
  attr_accessor :messages, :board, :players, :turn, :last_roll, :robbable
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
    if round == 1
      players[players.size - turn % players.size - 1]
    else
      players[turn % players.size]
    end
  end

  def available_actions(player)
    return [] unless player == active_player  # eventually, could "accept trade request"
    
    dev_card_actions(player) + case state
    when :preroll     then %w(roll)
    when :postroll    then %w(build_settlement build_city build_road buy_development_card trade_in pass_turn)
    when :robbing1    then %w(move_robber)
    when :robbing2    then %w(rob_player)
    when :start_turn1 then %w(build_settlement)
    when *FREE_ROAD_STATES then %w(build_road)
    else []
    end
  end

  def dev_card_actions(player)
    return [] if @dev_card_played
    cards = playable_dev_cards.map{|c| c.type.to_s }.uniq

    case state
    when :preroll then %w(knight) & cards
    when :postroll then cards
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
    @robbable = nil
    if @pre_knight_state
      self.state = @pre_knight_state
      @pre_knight_state = nil
    else
      self.state = :postroll
    end
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
    active_player.build_road(h(*v1), h(*v2), FREE_ROAD_STATES.include?(state))

    if state == :start_turn2
      @turn += 1
      self.state = (round >= 2) ? :preroll : :start_turn1
    elsif state == :road_building1
      self.state = :road_building2
    else
      self.state = :postroll
    end
  end

  def build_city(v1, v2, v3)
    active_player.build_city(h(*v1), h(*v2), h(*v3))
  end

  def build_settlement(v1, v2, v3)
    active_player.build_settlement(h(*v1), h(*v2), h(*v3), round == 0, round == 1)

    self.state = :start_turn2 if state == :start_turn1
  end

  def buy_development_card
    card = active_player.buy_development_card
    card.turn_purchased = turn
  end

  def trade_in(r1, r2)
    active_player.trade_in(r1, r2)
  end

  def pass_turn
    @turn += 1
    @dev_card_played = false
    self.state = :preroll
  end

  DEV_CARD_ACTIONS.each do |card|
    class_eval <<-RUBY
      def #{card}(*args)
        card = playable_dev_cards.detect{|c| c.type.to_s == '#{card}' }
        play_#{card}(*args)
        card.played = true
        @dev_card_played = true
      end
    RUBY
  end

  def playable_dev_cards
    active_player.development_cards.select{|c| c.playable_on_turn?(turn) }
  end

  def play_monopoly(resource)
    players.each do |player|
      n = player.send(resource)
      player.increment(resource, -n)
      active_player.increment(resource, n)
    end
  end

  def play_knight
    @pre_knight_state = state
    self.state = :robbing1
  end

  def play_year_of_plenty(resource1, resource2)
    active_player.increment(resource1, 1)
    active_player.increment(resource2, 1)
  end

  def play_road_building
    case active_player.roads.count
    when Player::MAX_ROADS
      # Player cannot build more roads, so the card should do nothing.
    when Player::MAX_ROADS - 1
      self.state = :road_building2
    else
      self.state = :road_building1
    end
  end

  def h(x, y)
    @board.hexes[x][y]
  end
end
