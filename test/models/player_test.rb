require_relative '../test_helper'

describe Player do

  before do
    @board = Board.create
    @player = Player.new(@board, 'puce')
  end

  def raises(msg, &block)
    error = assert_raises(RuntimeError, &block)
    error.message.must_match /#{msg}/
  end

  describe '#trade_in' do
    it 'raises an error when there are not enough resources' do
      raises('Not enough resources') { @player.trade_in('ore', 'wheat', 4) }
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
      raises('Already built 5') { @player.build_settlement(@hex1, @hex2, @hex3) }
    end

    it 'raises an error if hexes are not adjacent' do
      hex4 = @board.hexes[1][3]
      raises('Hexes are not adjacent') { @player.build_settlement(@hex1, @hex2, hex4) }
    end

    it 'raises an error if a settlement already exists nearby' do
      hex4 = @board.hexes[4][1]
      settlement = Settlement.new(@hex1, @hex2, hex4, @player)
      @board.settlements << settlement
      raises('Too close to existing settlement') { @player.build_settlement(@hex1, @hex2, hex4) }
      raises('Too close to existing settlement') { @player.build_settlement(@hex1, @hex2, @hex3) }
    end

    it 'raises an error if there is no road leading to the settlement' do
      raises('No road leading to settlement') { @player.build_settlement(@hex1, @hex2, @hex3) }
    end

    it 'raises an error if there are not enough resources' do
      @board.roads << Road.new(@hex1, @hex2, @player.color)
      @player.sheep = 1
      @player.wheat = 1
      @player.brick = 1
      raises('Not enough resources') { @player.build_settlement(@hex1, @hex2, @hex3) }
      @player.wood = 1
      @player.build_settlement(@hex1, @hex2, @hex3)
      @player.points.must_equal 1
      @player.n_settlements.must_equal 1
      [:sheep, :wheat, :brick, :wood].each do |attr|
        @player.send(attr).must_equal 0
      end
    end
  end

  describe '#build_road' do
    before do
      @hex1 = @board.hexes[3][2]
      @hex2 = @board.hexes[4][2]
      @hex3 = @board.hexes[3][3]
    end

    it 'raises an error if 15 roads are already built' do
      @player.n_roads = 15
      raises('Already built 15') { @player.build_road(@hex1, @hex2) }
    end

    it 'raises an error if no settlement or road leads to the road' do
      raises('Road not buildable there') { @player.build_road(@hex1, @hex2) }
      @board.roads << Road.new(@hex2, @hex3, 'orange')
      raises('Road not buildable there') { @player.build_road(@hex1, @hex2) }
    end

    it 'raises an error if there are not sufficient resources' do
      @board.roads << Road.new(@hex1, @hex3, @player.color)
      raises('Not enough resources') { @player.build_road(@hex1, @hex2) }
    end

    it 'succeeds otherwise' do
      @board.roads << Road.new(@hex1, @hex3, @player.color)
      @player.wood = 1
      @player.brick = 1
      @player.build_road(@hex1, @hex2)
      [:brick, :wood].each do |attr|
        @player.send(attr).must_equal 0
      end
    end
  end

  describe '#build_city' do
    before do
      @hex1 = @board.hexes[3][2]
      @hex2 = @board.hexes[4][2]
      @hex3 = @board.hexes[3][3]
    end

    it 'errors if there is no settlement at the location' do
      raises('No settlement at location') { @player.build_city(@hex1, @hex2, @hex3) } 
    end

    it 'errors if there is a settlement but not yours' do
      other_player = Player.new(@board, 'magenta')
      @board.settlements << Settlement.new(@hex1, @hex2, @hex3, other_player)
      raises('No settlement at location') { @player.build_city(@hex1, @hex2, @hex3) }
    end

    it 'errors if you lack resources' do
      @board.settlements << Settlement.new(@hex1, @hex2, @hex3, @player)
      raises('Not enough resources') { @player.build_city(@hex1, @hex2, @hex3) }
    end

    it 'succeeds otherwise' do
      @board.settlements << Settlement.new(@hex1, @hex2, @hex3, @player)
      @player.ore = 3
      @player.wheat = 2
      @player.points = 1
      @player.n_settlements = 1
      @player.build_city(@hex1, @hex2, @hex3)
      @player.points.must_equal 2
      @player.ore.must_equal 0
      @player.wheat.must_equal 0
      @player.n_settlements.must_equal 0
    end
  end
end
