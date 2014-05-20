require_relative '../test_helper'

describe 'board.erb' do
  before do
    @board = Board.new
    @player1 = Player.new(@board, 'red')
    @player2 = Player.new(@board, 'white')
    @player3 = Player.new(@board, 'blue')
    @board.settlements << Settlement.new(h(2,2), h(2,3), h(3,2), @player1)
    @board.roads << Road.new(h(2,2), h(2,3), 'red')
    $game = Game.new(board: @board, players: [@player1, @player2, @player3])
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
    @player1.wood = 1
    @player1.brick = 1
    @player1.wheat = 1
    @player1.sheep = 1
    visit '/?color=red'

    find('#build_road').click
    click_on_coords([4,1],[5,1])
    within('#error') { page.must_have_content 'Road not buildable' }

    find('#build_settlement').click
    click_on_coords([1,5],[2,5],[2,4])
    within('#error') { page.must_have_content 'No road leading' }
    click_on_coords([2,3],[1,3],[2,2])
    within('#error') { page.must_have_content 'Too close to existing' }
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
      page_must_display_resources(1, 'ore')
    end
    @player3.ore.must_equal 0
  end

  it 'allows discarding' do
    def $game.random_dieroll; 7; end
    @player2.ore = 10
    @player3.wheat = 4
    @player3.sheep = 4
    find('#roll').click
    page.has_css?('#move_robber').must_equal false

    visit "/?color=#{@player2.color}"
    find('#discard').click
    within('#discard-widget') do
      fill_in 'ore', with: 5
      find('#discard-submit').click
    end
    @player2.ore.must_equal 5

    visit "/?color=#{@player3.color}"
    find('#discard').click
    within('#discard-widget') do
      fill_in 'wheat', with: 2
      fill_in 'sheep', with: 2
      find('#discard-submit').click
    end
    @player3.wheat.must_equal 2
    @player3.sheep.must_equal 2

    visit "/?color=#{@player1.color}"
    page.must_have_css '#move_robber'
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
      page_must_display_resources(1, 'sheep')
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
      page_must_display_resources(1, 'ore')
      page_must_display_resources(1, 'wood')
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
      page_must_display_resources(5, 'brick')
    end
  end

  describe 'trading' do
    before do
      $game.state = :postroll
      @player1.ore = 1
      @player2.brick = 1
      visit '/?color=red'
      click_button 'request trade'

      within('#request_trade-widget') do
        within('.my-resources') do
          fill_in 'ore', with: 1
        end
        within('.your-resources') do
          fill_in 'brick', with: 1
        end
        click_button 'submit'
      end

      within('.trade-request') do
        page_must_display_resources(1, 'ore')
        page_must_display_resources(1, 'brick')
      end
    end

    it 'allows accepting' do
      visit "/?color=white"

      within('.trade-request') do
        page_must_display_resources(1, 'ore')
        page_must_display_resources(1, 'brick')
      end

      click_button 'accept trade'

      within('.player[data-color="white"]') do
        page_must_display_resources(0, 'brick')
        page_must_display_resources(1, 'ore')
      end

      visit '/?color=red'

      within('.player[data-color="red"]') do
        page_must_display_resources(1, 'brick')
        page_must_display_resources(0, 'ore')
      end
    end

    it 'allows canceling' do
      page.must_have_css '.trade-request'
      click_button 'cancel_trade'
      page.wont_have_css '.trade-request'
    end

    it 'allows rejecting of trading' do
      visit '/?color=white'
      page.must_have_css '.trade-request'
      click_button 'reject_trade'
      page.wont_have_css '.trade-request'
      visit '/?color=red'
      page.wont_have_css '.trade-request'
    end
  end

  it 'recognizes the winner (and his/her VPs)' do
    @board.settlements << Settlement.new(h(4,4), h(4,3), h(5,3), @player2)
    @board.settlements << Settlement.new(h(4,3), h(3,4), h(3,3), @player2)
    @player2.development_cards = [ DevCard.new(:victory_point) ]*8

    @player2.points.must_equal 10

    visit '/?color=red'

    page.must_have_css ".winner[data-color='#{@player2.color}']"
    page.must_have_css '.winner li', text: 'x8', count: 2
    page.must_have_css '.winner img[src*="victory_point"]'
  end

  def page_must_display_resources(count, resource)
    page.must_have_css ".resource-image-wrapper[data-resource='#{resource}']", count: count
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
