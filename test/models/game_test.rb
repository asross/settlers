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
    @game.available_actions(@player1).must_equal %w(build_settlement)
    @game.available_actions(@player2).must_equal []
    @game.available_actions(@player3).must_equal []
  end

  describe 'round 1' do
    describe '#build_settlement' do
      before do
        @game.perform_action(@player1, 'build_settlement', [[3,3],[3,2],[2,3]])
      end

      it 'updates state and board' do
        @board.settlements.count.must_equal 1
        @board.settlements.first.player.must_equal @player1
        @player1.resource_cards.must_equal []
        @game.state.must_equal :start_turn2
        @game.turn.must_equal 0
        @game.round.must_equal 0
        @game.active_player.must_equal @player1
        @game.available_actions(@player1).must_equal %w(build_road)
      end

      describe '#build_road' do
        before do
          @game.perform_action(@player1, 'build_road', [[3,3],[3,2]])
        end

        it 'updates state and board' do
          @board.roads.count.must_equal 1
          @board.roads.first.color.must_equal @player1.color
          @game.state.must_equal :start_turn1
          @game.turn.must_equal 1
          @game.round.must_equal 0
          @game.active_player.must_equal @player2
          @game.available_actions(@player2).must_equal %w(build_settlement)
        end
      end
    end
  end

  describe 'round 2 #build_settlement' do
    before do
      @game.turn = 3
      @game.perform_action(@player1, 'build_settlement', [[4,3],[4,4],[3,4]])
    end

    it 'updates state and board and awards resources' do
      @board.settlements.count.must_equal 1
      @board.settlements.first.player.must_equal @player1
      assert @player1.resource_cards.count >= 2
      @game.state.must_equal :start_turn2
    end
  end

  describe 'final #build_road of pregame' do
    before do
      @game.turn = 5
      @game.perform_action(@player3, 'build_settlement', [[4,3],[4,4],[3,4]])
      @game.perform_action(@player3, 'build_road', [[4,3],[4,4]])
    end

    it 'transitions to main game state machine' do
      @game.turn.must_equal 6
      @game.state.must_equal :preroll
      @game.active_player.must_equal @player1
    end
  end

  describe 'later rounds' do
    before do
      @game.turn = 6
    end

    describe '#roll' do
      before do
        @game.state = :preroll
        hexes = [h(3,3), h(3,4), h(4,3)]
        @board.settlements << Settlement.new(*hexes, @player1)
        @hex = hexes.detect{|h| h.type != 'desert'}
      end

      it 'initial state' do
        @game.available_actions(@player1).must_equal %w(roll)
        @game.last_roll.must_equal nil
        @player1.send(@hex.type).must_equal 0
      end

      it 'awards resources and transitions to postroll on non-7s' do
        $hex_number = @hex.number
        def @game.random_dieroll; $hex_number; end
        @game.perform_action(@player1, 'roll')
        @game.last_roll.must_equal @hex.number
        @game.state.must_equal :postroll
        @player1.send(@hex.type).must_equal 1
      end

      it 'transitions to robbing1 on 7s' do
        def @game.random_dieroll; 7; end
        @game.perform_action(@player1, 'roll')
        @game.last_roll.must_equal 7
        @game.state.must_equal :robbing1
      end
    end

    describe '#move_robber' do
      before do
        @game.state = :robbing1
        @board.robbed_hex.type.must_equal 'desert'
        @board.move_robber_to(3, 5, @player1) unless h(3,5).robbed
        @board.settlements << Settlement.new(h(3,3), h(3,4), h(4,3), @player1)
        @board.settlements << Settlement.new(h(3,3), h(3,2), h(4,2), @player2)
        @board.settlements << Settlement.new(h(3,3), h(2,3), h(2,4), @player3)
        @player2.ore = 1
        @player3.ore = 1
      end

      it 'transitions to postroll when there are no robbable players' do
        @game.perform_action(@player1, 'move_robber', [[3,1]])
        @game.state.must_equal :postroll
        @board.robbed_hex.must_equal h(3,1)
        h(3,5).robbed.must_equal false
        h(3,1).robbed.must_equal true
        @player1.ore.must_equal 0
        @player2.ore.must_equal 1
      end

      it 'steals and transitions to postroll when there is only one' do
        @game.perform_action(@player1, 'move_robber', [[3,2]])
        @game.state.must_equal :postroll
        @board.robbed_hex.must_equal h(3,2)
        h(3,5).robbed.must_equal false
        h(3,2).robbed.must_equal true
        @player1.ore.must_equal 1
        @player2.ore.must_equal 0
      end

      it 'transitions to robbing2 when there are multiple robbable players' do
        @game.perform_action(@player1, 'move_robber', [[3,3]])
        @game.state.must_equal :robbing2
        @board.robbed_hex.must_equal h(3,3)
        h(3,5).robbed.must_equal false
        h(3,3).robbed.must_equal true
        assert_similar @game.robbable, [@player2, @player3]
      end
    end

    describe '#rob_player' do
      before do
        @game.robbable = [@player2, @player3]
        @game.state = :robbing2
        @player2.wood = 1
      end

      it 'only allows stealing from robbable' do
        raises('invalid selection') { @game.perform_action(@player1, 'rob_player', @player1.color) }
      end

      it 'takes a resource away, unsets robbable, and transitions' do
        @player1.wood.must_equal 0
        @player2.wood.must_equal 1
        @game.perform_action(@player1, 'rob_player', @player2.color)
        @player1.wood.must_equal 1
        @player2.wood.must_equal 0
        @game.robbable.must_equal nil
        @game.state.must_equal :postroll
      end
    end

    it '#build_settlement'
    it '#build_city'
    it '#build_road'
    it '#trade_in'
    it '#pass_turn'
  end

end
