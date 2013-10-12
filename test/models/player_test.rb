require_relative '../test_helper'

describe Player do

  before do
    @board = Board.create
    @player = Player.new(@board, 'puce')
  end

  describe '#trade_in' do
    it 'raises an error when there are not enough resources' do
      raises('Not enough resources') { @player.trade_in('ore', 'wheat') }
    end

    it 'raises an error on invalid input' do
      @player.points = 10
      raises('Bad resource card') { @player.trade_in('points', 'wheat') }
    end

    it 'works if there are enough' do
      @player.sheep = 5
      @player.trade_in('sheep', 'wood')
      @player.sheep.must_equal 1
      @player.wood.must_equal 1
    end

    it 'requires only three on a 3:1' do
      @board.settlements << Settlement.new(h(2,1), h(2,2), h(3,1), @player)
      h(2,1).port_type = '3:1'
      h(2,1).port_direction = 'bottom'
      @player.sheep = 3
      @player.trade_in('sheep', 'wood')
      @player.sheep.must_equal 0
      @player.wood.must_equal 1
    end

    it 'requires only two on a 2:1 of the right type' do
      @board.settlements << Settlement.new(h(2,1), h(2,2), h(3,1), @player)
      h(2,1).port_type = 'sheep'
      h(2,1).port_direction = 'bottom'
      @player.sheep = 2
      @player.trade_in('sheep', 'wood')
      @player.sheep.must_equal 0
      @player.wood.must_equal 1
    end

    it 'works with cities, too' do
      Player::RESOURCE_CARDS.each{|r| @player.trade_in_ratio_for(r).must_equal 4 }
      settlement = Settlement.new(h(2,1), h(2,2), h(3,1), @player)
      h(2,1).port_type = '3:1'
      h(2,1).port_direction = 'bottom'
      @board.settlements << settlement
      Player::RESOURCE_CARDS.each{|r| @player.trade_in_ratio_for(r).must_equal 3 }
      settlement.size = 2
      Player::RESOURCE_CARDS.each{|r| @player.trade_in_ratio_for(r).must_equal 3 }
    end
  end

  describe '#build_settlement' do
    before do
      @hex1 = @board.hexes[3][2]
      @hex2 = @board.hexes[4][2]
      @hex3 = @board.hexes[3][3]
    end

    it 'raises an error if player has already build 5 settlements' do
      5.times { @board.settlements << Settlement.new(@hex1, @hex2, @hex3, @player) }
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
      @player.settlements.count.must_equal 1
      [:sheep, :wheat, :brick, :wood].each do |attr|
        @player.send(attr).must_equal 0
      end
    end

    it "does not require roads or resources on turn1" do
      @player.build_settlement(@hex1, @hex2, @hex3, true)
      @player.points.must_equal 1
      @player.settlements.count.must_equal 1
      @player.sheep.must_equal 0
      @player.wheat.must_equal 0
      @player.wood.must_equal 0
      @player.brick.must_equal 0
    end

    it "awards resources on turn2" do
      @player.build_settlement(@hex1, @hex2, @hex3, false, true)
      @player.points.must_equal 1
      @player.settlements.count.must_equal 1
      expected_total = [@hex1, @hex2, @hex3].count{|h| Player::RESOURCE_CARDS.include?(h.type) }
      [@player.ore, @player.sheep, @player.wheat, @player.wood, @player.brick].inject(:+).must_equal expected_total
    end
  end

  describe '#build_road' do
    before do
      @hex1 = @board.hexes[3][2]
      @hex2 = @board.hexes[4][2]
      @hex3 = @board.hexes[3][3]
    end

    it 'raises an error if 15 roads are already built' do
      15.times { @board.roads << Road.new(@hex2, @hex3, @player.color) }
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
      @player.brick.must_equal 0
      @player.wood.must_equal 0
    end

    it 'does not require resources on a start turn' do
      @board.roads << Road.new(@hex1, @hex3, @player.color)
      @player.build_road(@hex1, @hex2, true)
      @player.brick.must_equal 0
      @player.wood.must_equal 0
    end
  end

  describe 'steal' do
    before do
      @player.wood = 2
      @player.brick = 1
      @player.ore = 1
    end

    it '#resource_cards' do
      @player.resource_cards.must_equal %w(brick wood wood ore)
    end

    it '#steal_from' do
      other_player = Player.new(@board, 'umber')
      4.times { other_player.steal_from(@player) }
      @player.wood.must_equal 0
      @player.brick.must_equal 0
      @player.ore.must_equal 0
      other_player.wood.must_equal 2
      other_player.brick.must_equal 1
      other_player.ore.must_equal 1
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
      s = Settlement.new(@hex1, @hex2, @hex3, @player)
      @board.settlements << s
      @player.ore = 3
      @player.wheat = 2
      @player.points = 1
      @player.settlements.count.must_equal 1
      s.size.must_equal 1
      @player.build_city(@hex1, @hex2, @hex3)
      s.size.must_equal 2
      @player.points.must_equal 2
      @player.ore.must_equal 0
      @player.wheat.must_equal 0
      @player.settlements.count.must_equal 0
    end
  end

  describe '#buy_development_card' do
    it 'errors if you lack resources' do
      @board.development_cards = [ DevCard.new(:year_of_plenty) ]
      @player.ore = 0
      @player.wheat = 1
      @player.sheep = 1
      raises('Not enough resources') { @player.buy_development_card }
    end

    it 'errors if no cards are left' do
      @board.development_cards = []
      @player.ore = 1
      @player.wheat = 1
      @player.sheep = 1
      raises('deck is empty') { @player.buy_development_card }
    end

    it 'succeeds otherwise' do
      card = DevCard.new(:year_of_plenty)
      @board.development_cards = [ card ]
      @player.ore = 1
      @player.wheat = 1
      @player.sheep = 1
      @player.buy_development_card
      %w(ore wheat sheep).each{|r| @player.send(r).must_equal 0 }
      @player.development_cards.must_equal [ card ]
      @board.development_cards.must_equal []
    end
  end
end
