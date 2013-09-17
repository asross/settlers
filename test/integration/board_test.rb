require_relative '../test_helper'

describe 'board.erb' do
  before do
    @board = Board.create
    @player1 = Player.new(@board, 'red')
    @player2 = Player.new(@board, 'white')
    @player3 = Player.new(@board, 'blue')
    $game = Game.new(@board, [@player1, @player2, @player3])
    visit '/?color=red'
  end

  it 'has content for the players' do
    within('#players') do
      page.must_have_content 'red'
      page.must_have_content 'white'
      page.must_have_content 'blue'
    end
  end
end
