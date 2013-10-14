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

  it 'allows buying of dev cards' do
    $game.state = :postroll
    @player1.wheat = 1
    @player1.sheep = 1
    @player1.ore = 1
    visit '/?color=red'
    find('#buy_development_card').click
    @player1.development_cards.count.must_equal 1
    %w(ore wheat sheep).each{|r| @player1.send(r).must_equal 0 }
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

  it 'allows robber moving' do
    def $game.random_dieroll; 7; end
    @board.settlements << Settlement.new(h(4,4), h(4,3), h(5,3), @player2)
    @board.settlements << Settlement.new(h(4,3), h(3,4), h(3,3), @player3)
    @player3.ore = 1
    find('#roll').click
    find('#move_robber').click
    click_on_coords([4,3])
    find('#rob_player').click
    find(".player[data-color='#{@player3.color}'] .name").click
    within(".player[data-color='red']") do
      page.must_have_content '1 ore'
    end
    @player3.ore.must_equal 0
  end

  it 'allows city building' do
    @player1.ore = 3
    @player1.wheat = 2
    $game.state = :postroll
    visit '/?color=red'
    page.must_have_css '.city', count: 0
    find('#build_city').click
    click_on_coords([2,2],[2,3],[3,2])
    page.must_have_css '.city', count: 1
  end

  it 'allows X-for-1 resource trading' do
    @player1.wheat = 4
    $game.state = :postroll
    visit '/?color=red'
    find('#trade_in').click
    select 'wheat', from: 'resource1'
    select 'sheep', from: 'resource2'
    find('#trade-submit').click
    within('.player[data-color="red"]') do
      page.must_have_content '1 sheep'
    end
  end

  it 'allows turn passing' do
    $game.state = :postroll
    visit '/?color=red'
    page.must_have_css('.player.active[data-color="red"]')
    find('#pass_turn').click
    page.wont_have_css('.player.active[data-color="red"]')
    page.must_have_css(".player.active[data-color='#{@player2.color}']")
  end

  it 'allows playing knights' do
    $game.state = :postroll
    @player1.development_cards = [ DevCard.new(:knight) ]
    visit '/?color=red'
    find('#knight').click
    page.wont_have_css('.player[data-color="red"] #knight')
    page.must_have_css('.player[data-color="red"] #move_robber')
  end

  it 'allows playing road building' do
    $game.state = :postroll
    @player1.development_cards = [ DevCard.new(:road_building) ]
    visit '/?color=red'
    find('#road_building').click
    page.wont_have_css('.player[data-color="red"] #road_building')
    page.must_have_css('.player[data-color="red"] #build_road')
  end

  it 'allows playing year of plenty' do
    $game.state = :postroll
    @player1.development_cards = [ DevCard.new(:year_of_plenty) ]
    visit '/?color=red'
    find('#year_of_plenty').click
    select 'ore', from: 'resource1'
    select 'wood', from: 'resource2'
    find('#year-of-plenty-submit').click
    within('.player[data-color="red"]') do
      page.must_have_content '1 ore'
      page.must_have_content '1 wood'
    end
  end

  it 'allows playing monopoly' do
    $game.state = :postroll
    @player1.development_cards = [ DevCard.new(:monopoly) ]
    @player2.brick = 5
    visit '/?color=red'
    find('#monopoly').click
    select 'brick', from: 'resource'
    find('#monopoly-submit').click
    within('.player[data-color="red"]') do
      page.must_have_content '5 brick'
    end
  end

  def click_on_coords(*coords)
    if coords.size == 1
      # Need to click inside the hex
      find("[data-coords='#{coords.first}'] .number").click
    else
      coords.sort_by!{|el| el[0]+el[1] + 0.1*el[0]}
      find("[data-coords='#{coords}']").click
    end
  end
end
