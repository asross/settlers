require_relative '../test_helper'

describe Game do

  before do
    @board = Board.new
    @player1 = Player.new(@board, 'viridian')
    @player2 = Player.new(@board, 'cerulean')
    @player3 = Player.new(@board, 'alabaster')
    @game = Game.new(board: @board, players: [@player1, @player2, @player3])
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

        it 'saves message indicating action' do
          @game.messages.last.must_equal "** #{@player1.color} performed build_road!"
        end
      end
    end
  end

  describe 'round 2' do
    describe '#active_player' do
      it 'should go in reverse order' do
        @game.turn = 2
        @game.active_player.must_equal @player3
        @game.turn = 3
        @game.active_player.must_equal @player3
        @game.turn = 4
        @game.active_player.must_equal @player2
        @game.turn = 5
        @game.active_player.must_equal @player1
        @game.turn = 6
        @game.active_player.must_equal @player1
      end
    end

    describe '#build_settlement' do
      it 'updates state and board and awards resources' do
        @game.turn = 3
        @game.perform_action(@player3, 'build_settlement', [[4,3],[4,4],[3,4]])
        @board.settlements.count.must_equal 1
        @board.settlements.first.player.must_equal @player3
        assert @player3.resource_cards.count >= 2
        @game.state.must_equal :start_turn2
      end
    end
  end

  describe 'final #build_road of pregame' do
    before do
      @game.turn = 5
      @game.perform_action(@player1, 'build_settlement', [[4,3],[4,4],[3,4]])
      @game.perform_action(@player1, 'build_road', [[4,3],[4,4]])
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

      it 'awards 2 for cities' do
        $hex_number = @hex.number
        def @game.random_dieroll; $hex_number; end
        @player1.settlements.first.size = 2
        @game.perform_action(@player1, 'roll')
        @game.last_roll.must_equal @hex.number
        @game.state.must_equal :postroll
        @player1.send(@hex.type).must_equal 2
      end

      it 'transitions to robbing1 on 7s' do
        def @game.random_dieroll; 7; end
        @game.perform_action(@player1, 'roll')
        @game.last_roll.must_equal 7
        @game.state.must_equal :robbing1
      end

      it 'transitions to discard phase on 7 if players have >7 cards' do
        # p1 should discard 10
        @player1.ore = 20

        # p2 should discard 0
        @player2.wheat = 3

        # p3 should discard 5
        @player3.sheep = 4
        @player3.wheat = 4
        @player3.brick = 3

        # roll a 7
        def @game.random_dieroll; 7; end
        @game.perform_action(@player1, 'roll')
        @game.last_roll.must_equal 7

        # we should transition to discard
        @game.state.must_equal :discard
        @game.available_actions(@player1).must_equal %w(discard)
        @game.available_actions(@player2).must_equal []
        @game.available_actions(@player3).must_equal %w(discard)

        # discard actions have to happen in one go with extant resources
        raises("must discard exactly 10 cards") {
          @game.perform_action(@player1, 'discard', %w(ore))
        }
        raises("you do not have enough brick or sheep") {
          @game.perform_action(@player1, 'discard', %w(brick)*3 + %w(sheep)*7)
        }
        raises("must discard exactly 5 cards") {
          @game.perform_action(@player3, 'discard', %w(sheep wheat sheep brick))
        }
        raises("you do not have enough sheep") {
          @game.perform_action(@player3, 'discard', %w(sheep)*5)
        }

        # player1 discards
        @game.perform_action(@player1, 'discard', %w(ore)*10)
        @player1.ore.must_equal 10

        # now we're just waiting on p3
        @game.available_actions(@player1).must_equal [] # waits for player3
        @game.available_actions(@player2).must_equal []
        @game.available_actions(@player3).must_equal %w(discard)

        # player3 discards
        @game.perform_action(@player3, 'discard', %w(sheep sheep wheat wheat brick))
        @player3.sheep.must_equal 2
        @player3.wheat.must_equal 2
        @player3.brick.must_equal 2

        # now finally p1 can move the robber
        @game.state.must_equal :robbing1
        @game.available_actions(@player1).must_equal %w(move_robber)
        @game.available_actions(@player2).must_equal []
        @game.available_actions(@player3).must_equal []
      end
    end

    describe '#recalculate_longest_road' do
      before do
        @board.roads << Road.new(h(2,5),h(3,5), @player2.color)
        @board.roads << Road.new(h(2,5),h(3,4), @player2.color)
        @board.roads << Road.new(h(2,4),h(3,4), @player2.color)
        @board.roads << Road.new(h(2,4),h(3,3), @player2.color)
        @board.roads << Road.new(h(2,3),h(3,3), @player2.color)

        @board.roads << Road.new(h(3,1),h(3,2), @player1.color)
        @board.roads << Road.new(h(4,1),h(3,2), @player1.color)
        @board.roads << Road.new(h(4,1),h(4,2), @player1.color)
        @board.roads << Road.new(h(5,1),h(4,2), @player1.color)

        @game.send :recalculate_longest_road
        @game.longest_road_player.must_equal @player2
      end

      it 'recognizes the player with the longest road of sufficient length' do
        @board.roads << Road.new(h(5,1),h(5,2), @player1.color)
        @game.send :recalculate_longest_road
        @game.longest_road_player.must_equal @player2

        @board.roads << Road.new(h(6,1),h(5,2), @player1.color)
        @game.send :recalculate_longest_road
        @game.longest_road_player.must_equal @player1
      end

      it 'is called after building a road' do
        @game.state = :postroll
        @game.active_player.must_equal @player1
        @player1.wood = 2
        @player1.brick = 2
        @game.perform_action(@player1, 'build_road', [[5,1],[5,2]])
        @game.perform_action(@player1, 'build_road', [[6,1],[5,2]])
        @game.longest_road_player.must_equal @player1
      end

      it 'is called after building a settlement' do
        @game.state = :postroll
        @game.active_player.must_equal @player1
        @board.roads << Road.new(h(3,3),h(3,4), @player1.color)
        @player1.wood = 1
        @player1.brick = 1
        @player1.wheat = 1
        @player1.sheep = 1
        @game.perform_action(@player1, 'build_settlement', [[2,4],[3,3],[3,4]])
        @game.longest_road_player.must_equal nil
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

    it '#pass_turn' do
      old_turn = @game.turn
      @game.state = :postroll
      @game.perform_action(@player1, 'pass_turn')
      @game.active_player.must_equal @player2
      @game.turn.must_equal old_turn + 1
    end
  end

  describe 'development cards' do
    before do
      @game.turn = 6
      @game.state = :postroll
      @game.active_player.must_equal @player1
    end

    it 'pre-roll knight' do
      @game.state = :preroll
      ensure_robbed(1, 4)
      @player1.development_cards << DevCard.new(:knight)
      @board.settlements << Settlement.new(h(1,4), h(2,3), h(2,4), @player2)
      @board.settlements << Settlement.new(h(1,3), h(2,3), h(2,2), @player3)
      @player1.ore = 0
      @player2.ore = 1
      assert_similar @game.available_actions(@player1), %w(knight roll)
      @game.perform_action(@player1, 'knight')
      @game.state.must_equal :robbing1
      @game.perform_action(@player1, 'move_robber', [[2,3]])
      @game.state.must_equal :robbing2
      @game.perform_action(@player1, 'rob_player', @player2.color)
      @game.state.must_equal :preroll
      @player1.ore.must_equal 1
      @player2.ore.must_equal 0
    end

    it 'pre-roll knight without choices' do
      @game.state = :preroll
      ensure_robbed(1, 4)
      @player1.development_cards << DevCard.new(:knight)
      @board.settlements << Settlement.new(h(1,4), h(2,3), h(2,4), @player2)
      @player1.ore = 0
      @player2.ore = 1
      assert_similar @game.available_actions(@player1), %w(knight roll)
      @game.perform_action(@player1, 'knight')
      @game.state.must_equal :robbing1
      @game.perform_action(@player1, 'move_robber', [[2,3]])
      @game.state.must_equal :preroll
      @player1.ore.must_equal 1
      @player2.ore.must_equal 0
    end

    it 'post-roll knight' do
      @game.state = :postroll
      ensure_robbed(1, 4)
      @player1.development_cards << DevCard.new(:knight)
      @board.settlements << Settlement.new(h(1,4), h(2,3), h(2,4), @player2)
      @board.settlements << Settlement.new(h(1,3), h(2,3), h(2,2), @player3)
      @game.perform_action(@player1, 'knight')
      @game.state.must_equal :robbing1
      @game.perform_action(@player1, 'move_robber', [[2,3]])
      @game.state.must_equal :robbing2
      @game.perform_action(@player1, 'rob_player', @player2.color)
      @game.state.must_equal :postroll
    end

    it 'checking for largest army' do
      def played_knight
        DevCard.new(:knight).tap{|n| n.played = true }
      end
      def new_knight
        DevCard.new(:knight)
      end
      @player1.development_cards = [played_knight, played_knight, new_knight]
      @player2.development_cards = [played_knight]
      @player3.development_cards = [played_knight, played_knight]

      @game.largest_army_player.must_equal nil

      @game.state = :postroll
      @game.perform_action(@player1, 'knight')
      @game.largest_army_player.must_equal @player1

      @player3.development_cards << new_knight
      @player3.development_cards << new_knight

      2.times { @game.send(:pass_turn, nil) }
      @game.state = :postroll
      @game.perform_action(@player3, 'knight')
      @game.largest_army_player.must_equal @player1

      3.times { @game.send(:pass_turn, nil) }
      @game.state = :postroll
      @game.perform_action(@player3, 'knight')
      @game.largest_army_player.must_equal @player3
    end

    it 'monopoly' do
      @player1.development_cards << DevCard.new(:monopoly)
      @game.available_actions(@player1).must_include 'monopoly'
      @player1.wheat = 0
      @player2.wheat = 3
      @player3.wheat = 1
      @game.perform_action(@player1, 'monopoly', 'wheat')
      @game.state.must_equal :postroll
      @player1.wheat.must_equal 4
      @player2.wheat.must_equal 0
      @player3.wheat.must_equal 0
    end

    it 'year of plenty' do
      @player1.development_cards << DevCard.new(:year_of_plenty)
      @game.available_actions(@player1).must_include 'year_of_plenty'
      @player1.wheat = 0
      @game.perform_action(@player1, 'year_of_plenty', %w(wheat wheat))
      @game.state.must_equal :postroll
      @player1.wheat.must_equal 2
    end

    it 'road building' do
      @player1.development_cards << DevCard.new(:road_building)
      @board.settlements << Settlement.new(h(3,3), h(3,4), h(4,3), @player1)
      @game.available_actions(@player1).must_include 'road_building'
      @game.perform_action(@player1, 'road_building')
      @game.state.must_equal :road_building1
      @game.available_actions(@player1).must_equal %w(build_road)
      @game.perform_action(@player1, 'build_road', [[3,3],[3,4]])
      @game.state.must_equal :road_building2
      @game.perform_action(@player1, 'build_road', [[3,4],[2,4]])
      @game.state.must_equal :postroll
      @player1.roads.count.must_equal 2
    end

    it 'road building with 14 roads' do
      @player1.development_cards << DevCard.new(:road_building)
      @board.settlements << Settlement.new(h(3,3), h(3,4), h(4,3), @player1)
      14.times { @board.roads << Road.new(h(3,3), h(3,4), @player1.color) }
      @game.perform_action(@player1, 'road_building')
      @game.state.must_equal :road_building2
    end

    it 'road building with 15 roads' do
      @player1.development_cards << DevCard.new(:road_building)
      @board.settlements << Settlement.new(h(3,3), h(3,4), h(4,3), @player1)
      15.times { @board.roads << Road.new(h(3,3), h(3,4), @player1.color) }
      @game.perform_action(@player1, 'road_building')
      @game.state.must_equal :postroll
    end

    it 'does not allow more than one card per turn' do
      @player1.development_cards << DevCard.new(:monopoly)
      @player1.development_cards << DevCard.new(:road_building)
      @game.available_actions(@player1).must_include 'road_building'
      @game.perform_action(@player1, 'monopoly', 'wheat')
      @game.available_actions(@player1).wont_include 'road_building'
    end

    it 'does not allow replaying of played cards' do
      monopoly = DevCard.new(:monopoly)
      monopoly.played.must_equal false
      @player1.development_cards << monopoly
      @game.perform_action(@player1, 'monopoly', 'wheat')
      monopoly.played.must_equal true
    end

    it 'does not allow playing of just-bought cards' do
      monopoly = DevCard.new(:monopoly)
      @board.development_cards = [ monopoly ]
      @player1.ore = 1
      @player1.wheat = 1
      @player1.sheep = 1
      @game.perform_action(@player1, 'buy_development_card')
      @player1.development_cards.must_equal [ monopoly ]
      monopoly.turn_purchased.must_equal 6
      @game.available_actions(@player1).wont_include 'monopoly'
      @game.turn = 9
      @game.active_player.must_equal @player1
      @game.available_actions(@player1).must_include 'monopoly'
    end

    it 'victory points'
  end

  describe 'trading with other players' do
    before do
      @game.turn = 6
      @game.state = :postroll
      @game.active_player.must_equal @player1
    end

    it 'allows making trade requests if both players have the resources' do
      @player1.ore = 2
      @player1.wheat = 2
      @player2.sheep = 2
      @player2.brick = 1

      @game.perform_action(@player1, 'request_trade', [@player2.color, %w(ore ore wheat), %w(sheep sheep brick)])
      @game.perform_action(@player2, 'accept_trade')

      @player1.ore.must_equal 0
      @player1.wheat.must_equal 1
      @player1.sheep.must_equal 2
      @player1.brick.must_equal 1

      @player2.ore.must_equal 2
      @player2.wheat.must_equal 1
      @player2.sheep.must_equal 0
      @player2.brick.must_equal 0
    end

    it 'raises an error if the requesting or accepting player lacks resources' do
      raises('you do not have enough wheat') { @game.perform_action(@player1, 'request_trade', [@player2.color, %w(wheat), %w(sheep)]) }

      @player1.wheat = 1
      @game.perform_action(@player1, 'request_trade', [@player2.color, %w(wheat), %w(sheep)])

      raises('you do not have enough sheep') { @game.perform_action(@player2, 'accept_trade') }

      @player2.sheep = 1
      @player1.wheat = 0

      raises('you do not have enough wheat') { @game.perform_action(@player2, 'accept_trade') }

      @player1.wheat = 1
      @game.perform_action(@player2, 'accept_trade')

      @player1.wheat.must_equal 0
      @player1.sheep.must_equal 1

      @player2.wheat.must_equal 1
      @player2.sheep.must_equal 0

      @game.trade_requests[@player2.color].must_equal nil
    end

    it 'expires trade requests at end of turn' do
      @game.trade_requests[@player2.color].must_equal nil

      @player1.wheat = 1
      @game.perform_action(@player1, 'request_trade', [@player2.color, %w(wheat), %w(sheep)])

      @game.trade_requests[@player2.color].wont_equal nil

      @game.perform_action(@player1, 'pass_turn')

      @game.trade_requests[@player2.color].must_equal nil
    end

    it 'allows canceling of trade requests' do
      @player1.wheat = 1

      @game.perform_action(@player1, 'request_trade', [@player2.color, %w(wheat), %w(sheep)])
      @game.trade_requests[@player2.color].wont_equal nil

      @game.perform_action(@player1, 'cancel_trade')
      @game.trade_requests[@player2.color].must_equal nil
    end

    it 'allows rejection of trade requests' do
      @player1.wheat = 1

      @game.perform_action(@player1, 'request_trade', [@player2.color, %w(wheat), %w(sheep)])
      @game.trade_requests[@player2.color].wont_equal nil

      @game.perform_action(@player2, 'reject_trade')
      @game.trade_requests[@player2.color].must_equal nil
    end
  end
end
