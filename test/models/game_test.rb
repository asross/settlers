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

  # %w(roll build_settlement build_city build_road trade_in
  #    pass_turn move_robber rob_player)
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

  describe 'round 2' do
    before do
      @game.turn = 3
      @game.active_player.must_equal @player1
      @game.available_actions(@player1).must_equal %w(build_settlement)
    end

    describe '#build_settlement' do
      before do
        @game.perform_action(@player1, 'build_settlement', [[4,3],[4,4],[3,4]])
      end

      it 'updates state and board and awards resources' do
        @board.settlements.count.must_equal 1
        @board.settlements.first.player.must_equal @player1
        assert @player1.resource_cards.count >= 2
        @game.state.must_equal :start_turn2
      end
    end

    describe 'final #build_road' do
      before do
        @game.turn = 5
        @game.active_player.must_equal @player3
        @game.perform_action(@player3, 'build_settlement', [[4,3],[4,4],[3,4]])
        @game.state.must_equal :start_turn2
        @game.perform_action(@player3, 'build_road', [[4,3],[4,4]])
      end

      it 'transitions to main game state machine' do
        @game.state.must_equal :preroll
      end
    end
  end

  describe 'later rounds' do
    before do
      @game.turn = 6
      @game.active_player.must_equal @player1
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

    it '#build_settlement'
    it '#build_city'
    it '#build_road'
    it '#trade_in'
    it '#pass_turn'
    it '#move_robber'
    it '#rob_player'
  end

end
