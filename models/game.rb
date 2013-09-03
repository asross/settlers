class Game

  attr_accessor :messages
  attr_accessor :board, :players, :turn
  attr_accessor :state
  attr_reader :last_roll
  
  def initialize(board=nil, players=nil)
    @board = board || Board.create
    @players = players || %w(aqua deeppink gold lightcoral thistle).shuffle[0..2].map do |color|
      Player.new(@board, color)
    end
    @turn = 0
    @messages = []
  end

  def round
    turn % players.size
  end

  def active_player
    players[round]
  end

  def available_actions(player)
    return [] unless player == active_player  # eventually, could "accept trade request"
    return r1_actions(player) if round == 1
    return r2_actions(player) if round == 2
    
    case state
    when :preroll  then %w(roll)
    when :postroll then %w(build_settlement build_city build_road trade_in pass_turn)
    when :robbing1 then %w(move_robber)
    when :robbing2 then %w(rob_player)
    end
  end

  def error(msg)
    raise msg
  end

  def perform_action(player, action, *args)
    unless available_actions(player).include?(action)
      error "#{player.color} cannot perform #{action} at this time"
    end
    send(action, *args)
  end

  def roll
    @last_roll = 2 +rand(6) + rand(6)
    @board.rolled(@last_roll)
    if @last_roll == 7
      state = :robbing1
    else
      state = :postroll
    end
  end

  def move_robber(x, y)
    robbable = @board.move_robber_to(x, y, active_player)
    
    case robbable.size
    when 0
      state = :main
    when 1
      active_player.steal_from(robbable.first)
      state = :main
    else
      @robbable = robbable
      state = :choosing_robbee
    end
  end

  def rob_player(color)
    active_player.steal_from(players.detect{|p| p.color == color})

    state = :main
  end

  def h(x, y)
    @board.hexes[x][y]
  end

  def build_settlement(x1, y1, x2, y2, x3, y3)
    active_player.build_settlement(h(x1,y1), h(x2,y2), h(x3,y3))
  end


  #state_transitions do
    #within :pre_roll do
      ## transition_from :play_knight => :pre_roll
      #transition_from :roll => :main, :unless => ->(g) { g.roll == 7 }
      #transition_from :roll => :place_robber, :
    #end
   
    #within :main do
      ## transition_from :play_card => :main, :unless => ->(g) { g.played_card_yet? }
      #transition_from :build_settlement => :main
      #transition_from :build_city => :main
      #transition_from :build_road => :main
      #transition_from :trade_in => :main
      #transition_from 

    #end
    #transition_from 
  #end
  # (play knight)
  # roll
  # build settlement
  # build city
  # build road
  # trade in
  # (trade request)
  # (buy card)
  # (play card)
  # pass turn
  #
  # move robber
  # select player to steal from

end
