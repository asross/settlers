class Game

  attr_accessor :messages
  attr_accessor :board, :players, :turn
  attr_accessor :state

  def initialize(board=nil, players=nil)
    @board = board || Board.create
    @players = players || %w(aqua darkslateblue deeppink gold white lightcoral thistle).shuffle[0..2].map do |color|
      Player.new(@board, color)
    end
    @turn = 0
    @messages = []
  end

  def active_player
    @players[@turn % @players.size]
  end
end
