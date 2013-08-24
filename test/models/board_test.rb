require_relative '../test_helper'

describe Board do

  before do
    @board = Board.create
  end

  def h(x,y)
    @board.hexes[x][y]
  end

  def assert_similar(array1, array2)
    (array1 - array2).must_equal []
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
      hexes = @board.hexes_adjacent_to h(2,3)
      hexes.size.must_equal 6
      assert_similar hexes, [h(1,3),h(2,2),h(3,2),h(3,3),h(2,4),h(1,4)]
    end

    it 'works with two' do
      hexes = @board.hexes_adjacent_to(h(2,3), h(3,2))
      hexes.size.must_equal 2
      assert_similar hexes, [h(2,2), h(3,3)]
    end
  end

  describe '#roads_to and #road_to?' do
    before do
      @rg1 = Road.new(h(2,3), h(2,4), 'green')
      @rb1 = Road.new(h(2,3), h(3,3), 'black')
      @rg2 = Road.new(h(1,3), h(2,3), 'green')
      @rb2 = Road.new(h(2,4), h(3,4), 'black')
      @board.roads = [@rg1, @rb1, @rg2, @rb2]
    end

    it 'considers color' do
      green = @board.roads_to(h(2,3), h(2,4), h(3,3), 'green')
      black = @board.roads_to(h(2,3), h(2,4), h(3,3), 'black')
      assert_similar green, [@rg1]
      assert_similar black, [@rb1, @rb2]
    end

    it "doesn't get confused by nearby roads" do
      arg1 = [h(2,2), h(2,3), h(3,2), 'green']
      arg2 = [h(2,2), h(1,3), h(1,2), 'green']
      arg3 = [h(0,4), h(1,3), h(1,4), 'green']
      arg4 = [h(2,3), h(1,3), h(1,4), 'green']
      arg5 = [h(2,2), h(1,3), h(2,3), 'green']
      @board.roads_to(*arg1).must_equal []
      @board.roads_to(*arg2).must_equal []
      @board.roads_to(*arg3).must_equal []
      @board.roads_to(*arg4).must_equal [@rg2]
      @board.roads_to(*arg5).must_equal [@rg2]
      @board.road_to?(*arg1).must_equal false
      @board.road_to?(*arg2).must_equal false
      @board.road_to?(*arg3).must_equal false
      @board.road_to?(*arg4).must_equal true
      @board.road_to?(*arg5).must_equal true
    end
  end

  #describe '#road_to?' do
    #before do
      #@
    #end

  #end
  #describe '#settlement_at?'
  #describe '#road_buildable_at?'
  #describe '#settlement_near?'
  #describe '#upgrade_settlement'
  #describe '#check_for_longest_road'

end
