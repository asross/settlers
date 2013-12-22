require_relative '../test_helper'

describe Board do

  before do
    @board = Board.new
  end

  describe '.edge_pairs' do
    it 'returns an ordered list of all adjacent water/land hex pairs' do
      land_pieces = Board.edge_pairs(3).map{|e| e[1] }
      assert_similar land_pieces, [[1,3],[2,2],[3,1],[4,1],[5,1],[5,2],[5,3],[4,4],[3,5],[2,5],[1,5],[1,4]]
    end

    it 'grows by a factor of 12 in size' do
      1.upto(10).each do |i|
        Board.edge_pairs(i).count.must_equal ((i-0.5)*12)
      end
    end
  end

  describe '.port_locales' do
    it 'returns sensible port locations' do
      expected = {
        [2,1] => 'bottom',
        [4,0] => 'bottom',
        [0,3] => 'botright',
        [0,5] => 'topright',
        [1,6] => 'topright',
        [3,6] => 'top',
        [5,4] => 'topleft',
        [6,2] => 'topleft',
        [6,0] => 'botleft'
      }

      result = Board.port_locales(3)

      expected.keys.each do |k|
        expected[k].must_equal result[k]
      end
    end
  end

  describe '#move_robber_to' do
    it 'returns a list of all players the robber could affect' do
      ensure_robbed(1, 1)
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

  describe '#settlement_at?' do
    before do
      @player = Player.new(@board, 'gray')
      @settlement = Settlement.new(h(2,3),h(3,2),h(3,3), @player)
      @board.settlements << @settlement
    end

    it 'returns true only if a settlement is there' do
      @board.settlement_at?(h(2,3),h(3,2),h(2,2)).must_equal false
      @board.settlement_at?(h(2,3),h(3,2),h(3,3)).must_equal true
    end

    it 'considers color' do
      @board.settlement_at?(h(2,3),h(3,2),h(3,3),'black').must_equal false
      @board.settlement_at?(h(2,3),h(3,2),h(3,3),'gray').must_equal true
    end

    it 'can consider city status' do
      @board.settlement_at?(h(2,3),h(3,2),h(3,3),'gray',true).must_equal true
      @settlement.size = 2
      @board.settlement_at?(h(2,3),h(3,2),h(3,3),'gray',true).must_equal false
    end
  end

  describe '#road_buildable_at?' do
    it 'returns true if a same-color road leads there' do
      @board.roads << Road.new(h(2,3), h(2,4), 'red')
      @board.road_buildable_at?(h(1,4), h(2,4), 'red').must_equal true
      @board.road_buildable_at?(h(2,3), h(3,3), 'red').must_equal true
      @board.road_buildable_at?(h(2,4), h(3,3), 'red').must_equal true
      @board.road_buildable_at?(h(1,4), h(2,3), 'red').must_equal true
      @board.road_buildable_at?(h(1,4), h(2,3), 'black').must_equal false
    end

    it 'returns true if a same-color settlement is adjacent' do
      player = Player.new(@board, 'sienna')
      @board.settlements << Settlement.new(h(1,4),h(2,4),h(1,5),player)
      @board.road_buildable_at?(h(1,4),h(2,4),'sienna').must_equal true
      @board.road_buildable_at?(h(1,5),h(2,4),'sienna').must_equal true
      @board.road_buildable_at?(h(1,5),h(1,4),'sienna').must_equal true
      @board.road_buildable_at?(h(1,5),h(1,4),'ochre').must_equal false
    end

    it 'returns false if a road already exists (regardless of color)' do
      player = Player.new(@board, 'sienna')
      @board.settlements << Settlement.new(h(1,4),h(2,4),h(1,5),player)
      @board.roads << Road.new(h(1,4), h(2,4), 'red')
      @board.road_buildable_at?(h(1,4),h(2,4),'red').must_equal false
      @board.road_buildable_at?(h(1,4),h(2,4),'sienna').must_equal false
    end

    it 'returns false if there is nothing nearby' do
      @board.roads << Road.new(h(2,3), h(2,4), 'red')
      @board.road_buildable_at?(h(3,2), h(3,3), 'red').must_equal false
    end

    it 'returns false if a leading road is blocked by an off-color settlement' do
      player1 = Player.new(@board, 'red')
      player2 = Player.new(@board, 'sienna')
      @board.roads << Road.new(h(2,3), h(2,4), 'red')
      settlement = Settlement.new(h(2,3),h(2,4),h(1,4),player2)
      @board.settlements << settlement
      @board.road_buildable_at?(h(1,4), h(2,4), 'red').must_equal false
      @board.road_buildable_at?(h(1,4), h(2,3), 'red').must_equal false
      settlement.player = player1
      @board.road_buildable_at?(h(1,4), h(2,4), 'red').must_equal true
      @board.road_buildable_at?(h(1,4), h(2,3), 'red').must_equal true
    end
  end

  describe '#settlement_near?' do
    before do
      player = Player.new(@board, 'emerald')
      @board.settlements << Settlement.new(h(2,5),h(3,4),h(2,4), player)
    end

    it 'returns true for locations 0 and 1 away, false otherwise' do
      @board.settlement_near?(h(2,5),h(3,4),h(2,4)).must_equal true

      @board.settlement_near?(h(2,5),h(1,5),h(2,4)).must_equal true
      @board.settlement_near?(h(2,5),h(3,4),h(3,5)).must_equal true
      @board.settlement_near?(h(3,3),h(3,4),h(2,4)).must_equal true

      @board.settlement_near?(h(1,4),h(1,5),h(2,4)).must_equal false
      @board.settlement_near?(h(2,5),h(2,6),h(3,5)).must_equal false
      @board.settlement_near?(h(3,3),h(3,4),h(4,3)).must_equal false
    end
  end

  describe '#check_for_longest_road' do
    it 'straightish line' do
      @board.roads << (r1 = Road.new(h(2,5),h(3,5),'blue')) #  /
      @board.roads << (r2 = Road.new(h(2,5),h(3,4),'blue')) # /
      @board.roads << (r3 = Road.new(h(2,4),h(3,4),'blue')) # \
                                                            #  \
      @board.longest_path_from(r1).must_equal 3             #  /
      @board.longest_path_from(r2).must_equal 2             # /
      @board.longest_path_from(r3).must_equal 3
    end

    it 'line with offshoots' do
      @board.roads << (r1 = Road.new(h(2,5),h(3,5),'blue')) # \
      @board.roads << (r2 = Road.new(h(3,4),h(3,5),'blue')) #  \  _ _
      @board.roads << (r3 = Road.new(h(2,5),h(3,4),'blue')) #  /
                                                            # /
      @board.longest_path_from(r1).must_equal 2
      @board.longest_path_from(r2).must_equal 2
      @board.longest_path_from(r3).must_equal 2
    end

    it 'straight line with multiple colors' do
      @board.roads << (rb1 = Road.new(h(2,2),h(3,1),'red'))
      @board.roads << (rb2 = Road.new(h(3,2),h(3,1),'red'))
      @board.roads << (rb3 = Road.new(h(3,2),h(4,1),'red'))
      @board.roads << (rb4 = Road.new(h(4,2),h(4,1),'red'))
      @board.roads << (ru1 = Road.new(h(4,2),h(5,1),'blue'))

      @board.longest_path_from(rb1).must_equal 4
      @board.longest_path_from(rb2).must_equal 3
      @board.longest_path_from(rb3).must_equal 3
      @board.longest_path_from(rb4).must_equal 4
      @board.longest_path_from(ru1).must_equal 1
    end

    it 'halts at (offcolor) settlements' do
      red_player = Player.new(@board, 'red')
      blue_player = Player.new(@board, 'blue')
      @board.roads << (rb1 = Road.new(h(2,2),h(3,1),'red'))
      @board.roads << (rb2 = Road.new(h(3,2),h(3,1),'red'))
      @board.settlements << Settlement.new(h(3,2),h(3,1),h(4,1),red_player)
      @board.roads << (rb3 = Road.new(h(3,2),h(4,1),'red'))
      @board.roads << (rb4 = Road.new(h(4,2),h(4,1),'red'))
      @board.settlements << Settlement.new(h(4,2),h(4,1),h(5,1),blue_player)
      @board.roads << (rb5 = Road.new(h(4,2),h(5,1),'red'))

      @board.longest_path_from(rb1).must_equal 4
      @board.longest_path_from(rb2).must_equal 3
      @board.longest_path_from(rb3).must_equal 3
      @board.longest_path_from(rb4).must_equal 4
      @board.longest_path_from(rb5).must_equal 1

      @board.longest_road_length('red').must_equal 4
    end

    it 'simple cycle' do
      @board.roads << (r1 = Road.new(h(2,5),h(3,4),'topaz'))
      @board.roads << (r2 = Road.new(h(3,5),h(3,4),'topaz'))
      @board.roads << (r3 = Road.new(h(4,4),h(3,4),'topaz'))
      @board.roads << (r4 = Road.new(h(4,3),h(3,4),'topaz'))
      @board.roads << (r5 = Road.new(h(3,3),h(3,4),'topaz'))
      @board.roads << (r6 = Road.new(h(2,4),h(3,4),'topaz'))
      @board.roads << (r7 = Road.new(h(2,4),h(2,5),'topaz'))

      @board.longest_path_from(r1).must_equal 7
      @board.longest_path_from(r2).must_equal 6
      @board.longest_path_from(r3).must_equal 6
      @board.longest_path_from(r4).must_equal 6
      @board.longest_path_from(r5).must_equal 6
      @board.longest_path_from(r6).must_equal 7
      @board.longest_path_from(r7).must_equal 7

      @board.longest_road_length('topaz').must_equal 7
    end

    it 'complex cycle' do
      @board.roads << (r1 = Road.new(h(2,5),h(3,4),'aquamarine'))
      @board.roads << (r2 = Road.new(h(3,5),h(3,4),'aquamarine'))
      @board.roads << (r3 = Road.new(h(4,4),h(3,4),'aquamarine'))
      @board.roads << (r4 = Road.new(h(4,3),h(3,4),'aquamarine'))
      @board.roads << (r5 = Road.new(h(3,3),h(3,4),'aquamarine'))
      @board.roads << (r6 = Road.new(h(2,4),h(3,4),'aquamarine'))
      @board.roads << (r7 = Road.new(h(4,4),h(4,3),'aquamarine'))
      @board.roads << (r8 = Road.new(h(5,3),h(4,3),'aquamarine'))
      @board.roads << (r9 = Road.new(h(5,2),h(4,3),'aquamarine'))
      @board.roads << (r10 = Road.new(h(4,2),h(4,3),'aquamarine'))
      @board.roads << (r11 = Road.new(h(3,3),h(4,3),'aquamarine'))
      @board.roads << (r12 = Road.new(h(3,3),h(4,2),'aquamarine'))
      @board.roads << (r13 = Road.new(h(5,3),h(5,2),'aquamarine'))
      @board.roads << (r14 = Road.new(h(6,2),h(5,2),'aquamarine'))

      @board.longest_path_from(r14).must_equal 12

      @board.longest_road_length('aquamarine').must_equal 12
    end
  end
end
