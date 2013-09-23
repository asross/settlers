require 'sinatra'
require 'json'
require 'pry'
require_relative 'models/catan'
Dir.glob('./models/*.rb').each { |f| require f }

$game = Game.new

get '/' do
  @game = $game
  redirect "/?color=#{$game.players.sample.color}" unless current_player
  erb :board
end

post '/messages' do
  $game.messages << [current_player.color, params['message']] if params['message']
  redirect request.referer
end

post '/actions' do
  data = JSON.parse(params[:data])
  begin
    $game.perform_action(current_player, data['action'], data['args'])
    status 200
  rescue CatanError => e
    status 400
    body e.message
  end
end

def current_player
  @player ||= $game.players.detect{|p| p.color == params['color']}
end
