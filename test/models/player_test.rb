require_relative '../test_helper'

describe Player do
  
  before do
    @board = Board.create
    @player = Player.new(@board, 'puce')
  end

  describe '#trade_in' do

    it 'raises an error when there are not enough resources' do
      assert_raises(RuntimeError) { @player.trade_in('ore', 'wheat', 4) }
    end

    it 'works if there are enough' do
      @player.sheep = 5
      @player.trade_in('sheep', 'wood', 3)
      @player.sheep.must_equal 2
      @player.wood.must_equal 1
    end
  end

  describe '#build_settlement' do
    before do
      @hex1 = @board.hexes[3][2]
      @hex2 = @board.hexes[4][2]
      @hex3 = @board.hexes[3][3]
    end

    it 'raises an error if player has already build 5 settlements' do
      @player.n_settlements = 5
      assert_raises(RuntimeError) { @player.build_settlement(@hex1, @hex2, @hex3) }
    end
  end

  describe '#build_road' do
  end

  describe '#build_city' do
  end

end
