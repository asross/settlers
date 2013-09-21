require_relative '../test_helper'

describe 'board.erb' do
  before do
    @board = Board.create
    @player1 = Player.new(@board, 'red')
    @player2 = Player.new(@board, 'white')
    @player3 = Player.new(@board, 'blue')
    $game = Game.new(@board, [@player1, @player2, @player3])
    Capybara.current_driver = Capybara.javascript_driver
    visit '/?color=red'
  end

  after do
    Capybara.current_driver = :rack_test
  end

  it 'has content for the players' do
    within('#players') do
      page.must_have_content 'red'
      page.must_have_content 'white'
      page.must_have_content 'blue'
    end
  end

  it 'allows messaging' do
    fill_in 'message', with: 'cardamom'
    find('input[name="message"]').native.send_keys(:return)
    within('#message-area') do
      page.must_have_content 'red: cardamom'
    end
  end
end
