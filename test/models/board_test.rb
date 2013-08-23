require_relative '../test_helper'

describe Board do

  before do
    @board = Board.create
  end

  def h(x,y)
    @board.hexes[x][y]
  end

  describe '#move_robber_to' do
    it 'returns a list of all players the robber could affect' do
      player = Player.new(@board, 'green')
      raises('invalid robber location') { @board.move_robber_to(20,20,player) }
      @board.move_robber_to(3,3,player).must_equal []
      @board.robbed_hex.x.must_equal 3
      @board.robbed_hex.y.must_equal 3
      @board.robbed_hex.robbed.must_equal true
      @board.hexes.flatten.select{|h| h.robbed }.size.must_equal 1
      raises('cannot pick same location') { @board.move_robber_to(3,3,player) }
      @board.settlements << Settlement.new(h(3,3),h(3,2),h(4,2),player)
      @board.move_robber_to(4,2,player).must_equal []
      @board.robbed_hex.x.must_equal 4
      @board.robbed_hex.y.must_equal 2
      @board.robbed_hex.robbed.must_equal true
      @board.hexes.flatten.select{|h| h.robbed }.size.must_equal 1
      player2 = Player.new(@board, 'red')
      @board.settlements << Settlement.new(h(3,3),h(2,4),h(3,4),player2)
      @board.move_robber_to(3,3,player).must_equal [player2]
    end
  end

  describe '#hexes_adjacent_to' do
    it 'works with one' do
      @board.hexes_adjacent_to(h(2,3)).size.must_equal 6
      (@board.hexes_adjacent_to(h(2,3)).map{|h| [h.x, h.y]} -
        [[1,3],[2,2],[3,2],[3,3],[2,4],[1,4]]).must_equal []
    end

    it 'works with two' do
      @board.hexes_adjacent_to(h(2,3), h(3,2)).size.must_equal 2
      (@board.hexes_adjacent_to(h(2,3), h(3,2)).map{|h| [h.x, h.y]} -
        [[2,2],[3,3]]).must_equal []
    end
  end

  describe '#road_to?' do

  end
  #describe '#roads_to'
  #describe '#settlement_at?'
  #describe '#road_buildable_at?'
  #describe '#settlement_near?'
  #describe '#upgrade_settlement'
  #describe '#check_for_longest_road'

end
