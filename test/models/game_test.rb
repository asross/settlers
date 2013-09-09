require_relative '../test_helper'

describe Game do

  before do
    @board = Board.create
    @player1 = Player.new(@board, 'viridian')
    @player2 = Player.new(@board, 'cerulean')
    @player3 = Player.new(@board, 'alabaster')
    @game = Game.new(@board, [@player1, @player2, @player3])
  end

  it 'has proper initial state' do
    @game.state.must_equal :start_turn1
    @game.turn.must_equal 0
    @game.round.must_equal 0
    @game.active_player.must_equal @player1
  end

end
