require_relative '../test_helper'

describe 'board.erb' do
  before do
    @board = Board.create
    @player1 = Player.new(@board, 'red')
    @player2 = Player.new(@board, 'white')
    @player3 = Player.new(@board, 'blue')
    @board.settlements << Settlement.new(h(2,2), h(2,3), h(3,2), @player1)
    @board.roads << Road.new(h(2,2), h(2,3), 'red')
    $game = Game.new(@board, [@player1, @player2, @player3])
    $game.turn = 6
    $game.state = :preroll
    Capybara.current_driver = Capybara.javascript_driver
    visit '/?color=red'
  end

  after do
    Capybara.current_driver = :rack_test
  end

  it 'has content for the players, settlements, and roads' do
    within('#players') do
      page.must_have_content 'red'
      page.must_have_content 'white'
      page.must_have_content 'blue'
    end
    page.must_have_css '.settlement[data-color="red"]', count: 1
    page.must_have_css '.road[data-color="red"]', count: 1
  end

  it 'allows messaging' do
    fill_in 'message', with: 'cardamom'
    find('input[name="message"]').native.send_keys(:return)
    within('#message-area') do
      page.must_have_content 'red: cardamom'
    end
  end

  it 'allows rolling' do
    find('#roll').click
    within('#last-roll') do
      page.must_have_content $game.last_roll
    end
    assert $game.state != :preroll
  end

  it 'allows building of settlements and roads' do
    $game.state = :postroll
    @player1.wheat = 1
    @player1.sheep = 1
    @player1.brick = 2
    @player1.wood = 2
    visit '/?color=red'
    find('#build_road').click
    click_on_coords([1,3],[2,3])
    find('#build_settlement').click
    click_on_coords([2,3],[1,3],[1,4])
    page.must_have_css '.road[data-color="red"]', count: 2
    page.must_have_css '.settlement[data-color="red"]', count: 2
    @player1.resource_cards.must_equal []
  end

  it 'displays errors' do
    $game.state = :postroll
    @board.roads << Road.new(h(1,3), h(2,3), 'red')
    visit '/?color=red'

    find('#build_road').click
    click_on_coords([4,1],[5,1])
    within('#error') { page.must_have_content 'Road not buildable' }
    click_on_coords([1,4],[2,3])
    within('#error') { page.must_have_content 'Not enough resources' }

    find('#build_settlement').click
    click_on_coords([1,5],[2,5],[2,4])
    within('#error') { page.must_have_content 'No road leading' }
    click_on_coords([2,3],[1,3],[2,2])
    within('#error') { page.must_have_content 'Too close to existing' }
    click_on_coords([2,3],[1,3],[1,4])
    within('#error') { page.must_have_content 'Not enough resources' }
  end

  it 'allows city building'
  it 'allows X-for-1 resource trading'
  it 'allows turn passing'
  it 'allows robber moving'

  def click_on_coords(*coords)
    coords.sort_by!{|el| el[0]+el[1] + 0.1*el[0]}
    find("[data-coords='#{coords}']").click
  end
end
