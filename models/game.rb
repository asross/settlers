class Game < Catan
  STATES = [:preroll, :postroll, :robbing1, :robbing2, :start_turn1, :start_turn2, :road_building1, :road_building2, :discard]
  FREE_ROAD_STATES = [:start_turn2, :road_building1, :road_building2]
  DEV_CARD_ACTIONS = %w(monopoly knight year_of_plenty road_building)
  ACTIONS = %w(roll build_settlement build_city build_road buy_development_card trade_in move_robber rob_player discard request_trade accept_trade pass_turn) + DEV_CARD_ACTIONS
  COLORS = %w(aqua deeppink gold lightcoral thistle burlywood azure lawngreen)

  attr_accessor :messages, :board, :players, :turn, :last_roll, :robbable
  attr_reader :state
  attr_reader :longest_road_player, :largest_army_player

  def initialize(opts={})
    opts[:side_length] ||= 3
    opts[:n_players] ||= 3

    @board = opts[:board] || Board.new(opts)
    @players = opts[:players] || COLORS.shuffle.take(opts[:n_players]).map do |c|
      Player.new(@board, c)
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
    return %w(discard) if should_discard?(player)

    if player != active_player
      if trade_requests[player.color]
        return %w(accept_trade)
      else
        return []
      end
    end

    dev_card_actions(player) + case state
    when :preroll     then %w(roll)
    when :postroll    then %w(build_settlement build_city build_road buy_development_card trade_in pass_turn request_trade)
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

    # ugh -- some actions need to be player specific.
    if %w(discard accept_trade).include?(action)
      args = [player]+args
    end

    send(action, *args)
  end

  def display_points(player)
    total = player.points
    total += 2 if player == longest_road_player
    total += 2 if player == largest_army_player
    total
  end

  def state=(s)
    raise ArgumentError, "invalid state #{s}" unless STATES.include?(s)
    @state = s
  end

  def trade_requests
    @trade_requests ||= {}
  end

  private

  def random_dieroll
    2 + rand(6) + rand(6)
  end

  def roll
    @last_roll = random_dieroll
    @board.rolled(@last_roll)
    if @last_roll == 7
      if players.any?{|p| p.resource_cards.count > 7}
        self.state = :discard
      else
        self.state = :robbing1
      end
    else
      self.state = :postroll
    end
  end

  def rob_player(color)
    robbee = @robbable.detect{|p| p.color == color}
    error "invalid selection #{color} (must pick one of #{@robbable.join(', ')})" unless robbee
    active_player.steal_from(robbee)
    @robbable = nil
    self.state = @pre_knight_state || :postroll
    @pre_knight_state = nil
  end

  def move_robber(v)
    robbable = @board.move_robber_to(*v, active_player)
    case robbable.size
    when 0
      self.state = :postroll
    when 1
      active_player.steal_from(robbable.first)
      self.state = @pre_knight_state || :postroll
      @pre_knight_state = nil
    else
      @robbable = robbable
      self.state = :robbing2
    end
  end

  def discards_this_turn
    @discards_this_turn ||= []
  end

  def should_discard?(player)
    state == :discard &&
      player.resource_cards.count > 7 &&
      !discards_this_turn.include?(player)
  end

  def discard(player, *resources)
    player.discard(*resources)
    discards_this_turn << player
    if players.none?(&method(:should_discard?))
      @discards_this_turn = nil
      self.state = :robbing1
    end
  end

  def build_road(v1, v2)
    active_player.build_road(h(*v1), h(*v2), FREE_ROAD_STATES.include?(state))
    recalculate_longest_road

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
    recalculate_longest_road # settlement building might break an existing road

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
    @trade_requests = {}
    @last_roll = nil
    self.state = :preroll
  end

  def request_trade(color, my_resources, your_resources)
    active_player.assert_we_have(my_resources)
    trade_requests[color] = [my_resources, your_resources]
  end

  def accept_trade(accepting_player)
   active_player_resources, accepting_player_resources = trade_requests[accepting_player.color]

   active_player.assert_we_have(active_player_resources)
   accepting_player.assert_we_have(accepting_player_resources)

   active_player_resources.each do |resource|
     active_player.increment(resource, -1)
     accepting_player.increment(resource, 1)
   end

   accepting_player_resources.each do |resource|
     active_player.increment(resource, 1)
     accepting_player.increment(resource, -1)
   end

   trade_requests.delete(accepting_player.color)
  end

  DEV_CARD_ACTIONS.each do |card|
    class_eval <<-RUBY
      def #{card}(*args)
        card = playable_dev_cards.detect(&:#{card}?)
        play_#{card}(*args)
        card.played = true
        recalculate_largest_army if card.knight?
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

  def recalculate(leader_var, method, min)
    if leader = instance_variable_get(leader_var)
      score_to_beat = [min, leader.send(method)].max
    else
      score_to_beat = min
    end

    new_leader = players.max_by(&method)
    best_score = new_leader.send(method)

    if best_score > score_to_beat
      instance_variable_set(leader_var, new_leader)
    elsif best_score <= min
      instance_variable_set(leader_var, nil)
    end
  end

  def recalculate_longest_road
    recalculate(:@longest_road_player, :road_length, 4)
  end

  def recalculate_largest_army
    recalculate(:@largest_army_player, :knights_played, 2)
  end

  def h(x, y)
    @board.hexes[x][y]
  end
end
