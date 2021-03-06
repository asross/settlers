require_relative './dev_card'

class Game < Catan
  FREE_ROAD_STATES = [:start_turn2, :road_building1, :road_building2]
  OFF_TURN_ACTIONS = %w(discard accept_trade reject_trade)
  STATES_TO_ACTIONS = {
    :preroll => %w(roll knight),
    :postroll => %w(
      monopoly knight year_of_plenty road_building
      build_settlement build_city build_road buy_development_card
      trade_in request_trade
      accept_trade reject_trade cancel_trade
      pass_turn
    ),
    :robbing1 => %w(move_robber),
    :robbing2 => %w(rob_player),
    :start_turn1 => %w(build_settlement),
    :start_turn2 => %w(build_road),
    :road_building1 => %w(build_road),
    :road_building2 => %w(build_road),
    :discard => %w(discard)
  }
  STATES = STATES_TO_ACTIONS.keys
  ACTIONS = STATES_TO_ACTIONS.values.flatten.uniq
  COLORS = %w(aqua gold lightcoral thistle azure lawngreen)

  attr_accessor :messages, :board, :players, :turn, :last_roll, :robbable, :state
  attr_reader :longest_road_player, :largest_army_player, :trade_requests, :discards_this_turn, :id, :started_at, :action_count, :max_cards, :points_to_win

  def initialize(opts={})
    opts[:side_length] ||= 3
    opts[:n_players] ||= 3
    opts[:max_cards] ||= 7
    opts[:points_to_win] ||= 10

    @id = opts[:id] || SecureRandom.uuid
    @started_at = Time.now
    @board = opts[:board] || Board.new(opts)
    @players = opts[:players] || COLORS.shuffle.take(opts[:n_players]).map do |c|
      Player.new(@board, c, max_cards: opts[:max_cards])
    end

    @turn = 0
    @action_count = 0
    @messages = []
    @state = :start_turn1
    @trade_requests = {}
    @discards_this_turn = []
    @max_cards = opts[:max_cards]
    @points_to_win = opts[:points_to_win]
  end

  def as_json
    {
      id: id,
      board: @board.as_json,
      players: @players.map(&:as_json),
      messages: @messages,
      last_roll: @last_roll,
      available_actions: @players.each_with_object({}) {|p,h| h[p.color] = available_actions(p) },
      trade_requests: @trade_requests,
      longest_road_player: @longest_road_player,
      largest_army_player: @largest_army_player,
      active_player: active_player.color,
      action_count: @action_count,
      turn: @turn
    }
  end

  def over?
    players.any?(&method(:winner?))
  end

  def winner?(player)
    points = player.points
    points += 2 if player == longest_road_player
    points += 2 if player == largest_army_player
    points >= points_to_win
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
    STATES_TO_ACTIONS[state].select do |act|
      # only the active player can perform most actions
      next unless player == active_player || OFF_TURN_ACTIONS.include?(act)

      # if there is a method to determine whether this action can be performed,
      # call it to help filter
      next unless !respond_to?("can_#{act}?", true) || send("can_#{act}?", player)

      # if we pass both of these tests, the action is available
      true
    end
  end

  def perform_action(player, action, args=[])
    avail = available_actions(player)

    unless ACTIONS.include?(action)
      error "invalid action #{action.inspect}. #{avail.any?? "Available actions are #{avail}" : ""}"
    end

    unless avail.include?(action)
      error "#{player.color} cannot perform #{action} at this time"
    end

    send(action, player, *args)

    @messages << message_for(player, action, args) #"#{player.color} performed #{action}!"
    @action_count += 1
  end

  private

  def message_for(player, action, args)
    case action
    when "request_trade"
      r1 = args[1].size > 0 ? args[1].join("+") : 'friendship'
      r2 = args[2].size > 0 ? args[2].join("+") : 'friendship'
      "#{player.color} offered their #{r1} for #{args[0]}'s #{r2}"
    when "cancel_trade"
      "#{player.color} revoked their offer!"
    when "accept_trade"
      "#{player.color} accepted the offer!"
    when "discard"
      "#{player.color} had to discard #{args.size} cards :("
    when /^build_[a-z]+$/
      "#{player.color} built a #{action.split("_")[1]}!"
    when "move_robber"
      "#{player.color} moved the robber!"
    when "rob_player"
      "#{player.color} stole from #{args}!"
    when "monopoly", "knight", "year_of_plenty", "road_building"
      "#{player.color} played #{action.gsub("_", " ")}!"
    when "buy_development_card"
      "#{player.color} bought a dev card!"
    when "trade_in"
      "#{player.color} traded in #{args[0]} for #{args[1]}!"
    when "pass_turn"
      "#{player.color} passed the turn to #{active_player.color}!"
    when "roll"
      if @last_roll == 7 && @state == :discard
        "#{player.color} rolled a #{@last_roll}! #{players_with_many_cards.map(&:color).join(' and ')} must discard..."
      else
        "#{player.color} rolled a #{@last_roll}!"
      end
    else
      "#{player.color} performed #{action}!"
    end
  end

  def random_dieroll
    2 + rand(6) + rand(6)
  end

  def players_with_many_cards
    players.select{|p| p.resource_cards.count > max_cards}
  end

  def roll(player)
    @last_roll = random_dieroll
    @board.rolled(@last_roll)
    if @last_roll == 7
      if players_with_many_cards.any?
        @state = :discard
      else
        @state = :robbing1
      end
    else
      @state = :postroll
    end
  end

  def rob_player(robbing_player, color)
    robbee = @robbable.detect{|p| p.color == color}
    error "invalid selection #{color} (must pick one of #{@robbable.join(', ')})" unless robbee
    robbing_player.steal_from(robbee)
    @robbable = nil
    @state = @pre_knight_state || :postroll
    @pre_knight_state = nil
  end

  def move_robber(player, v)
    robbable = @board.move_robber_to(*v, player)
    case robbable.size
    when 0
      @state = :postroll
    when 1
      player.steal_from(robbable.first)
      @state = @pre_knight_state || :postroll
      @pre_knight_state = nil
    else
      @robbable = robbable
      @state = :robbing2
    end
  end

  def discard(player, *resources)
    player.discard(*resources)
    discards_this_turn << player
    if players.none?(&method(:can_discard?))
      @discards_this_turn = []
      @state = :robbing1
    end
  end

  def build_road(player, v1, v2)
    player.build_road(h(*v1), h(*v2), FREE_ROAD_STATES.include?(state))
    recalculate_longest_road

    if state == :start_turn2
      @turn += 1
      @state = (round >= 2) ? :preroll : :start_turn1
    elsif state == :road_building1
      @state = :road_building2
    else
      @state = :postroll
    end
  end

  def build_city(player, v1, v2, v3)
    player.build_city(h(*v1), h(*v2), h(*v3))
  end

  def build_settlement(player, v1, v2, v3)
    player.build_settlement(h(*v1), h(*v2), h(*v3), round == 0, round == 1)
    recalculate_longest_road # settlement building might break an existing road

    @state = :start_turn2 if state == :start_turn1
  end

  def buy_development_card(player)
    card = player.buy_development_card
    card.turn_purchased = turn
  end

  def trade_in(player, r1, r2)
    player.trade_in(r1, r2)
  end

  def pass_turn(player)
    @turn += 1
    @dev_card_played = false
    @trade_requests = {}
    @last_roll = nil
    @state = :preroll
  end

  def request_trade(player, color, my_resources, your_resources)
    player.assert_we_have(my_resources)
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

  def cancel_trade(player)
    trade_requests.clear
  end

  def reject_trade(player)
    trade_requests.delete(player.color)
  end

  def find_development_card(type)
    active_player.development_cards.detect{|c| c.playable_on_turn?(turn) && c.type == type }
  end

  def play_development_card(card_type)
    card = find_development_card(card_type)
    yield
    card.played = true
    @dev_card_played = true
  end

  DevCard::TYPES.each do |card_type|
    define_method "can_#{card_type}?" do |player|
      !@dev_card_played && find_development_card(card_type)
    end
  end

  def monopoly(player, resource)
    play_development_card(:monopoly) do
      players.each do |robbed|
        n = robbed.send(resource)
        robbed.increment(resource, -n)
        player.increment(resource, n)
      end
    end
  end

  def knight(player)
    play_development_card(:knight) do
      @pre_knight_state = state
      @state = :robbing1
    end
    recalculate_largest_army
  end

  def year_of_plenty(player, resource1, resource2)
    play_development_card(:year_of_plenty) do
      player.increment(resource1, 1)
      player.increment(resource2, 1)
    end
  end

  def road_building(player)
    play_development_card(:road_building) do
      case player.roads.count
      when Player::MAX_ROADS
        # Player cannot build more roads, so the card should do nothing.
      when Player::MAX_ROADS - 1
        @state = :road_building2
      else
        @state = :road_building1
      end
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

  def can_build_settlement?(player)
    return false unless player.remaining_settlement_count > 0
    round <= 1 || player.has_resources?(%w(wheat brick sheep wood))
  end

  def can_build_road?(player)
    return false unless player.remaining_road_count > 0
    FREE_ROAD_STATES.include?(state) || player.has_resources?(%w(wood brick))
  end

  def can_buy_development_card?(player)
    return false unless player.remaining_dev_card_count > 0
    player.has_resources?(%w(sheep ore wheat))
  end

  def can_build_city?(player)
    return false unless player.remaining_city_count > 0
    player.has_resources?(%w(wheat wheat ore ore ore))
  end

  def can_trade_in?(player)
    Player::RESOURCE_CARDS.any? do |resource|
      player.trade_in_ratio_for(resource) <= player.send(resource)
    end
  end

  def can_discard?(player)
    player.resource_cards.count > max_cards && !discards_this_turn.include?(player)
  end

  def can_accept_trade?(player)
    trade_requests[player.color]
  end

  def can_reject_trade?(player)
    trade_requests[player.color]
  end

  def can_cancel_trade?(player)
    trade_requests.size > 0
  end
end
