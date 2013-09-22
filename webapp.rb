require 'sinatra'
require 'json'
require 'pry'
require_relative 'models/catan'
Dir.glob('./models/*.rb').each { |f| require f }

$game = Game.new

get '/' do
  @game = $game
  @player = current_player
  redirect "/?color=#{$game.players.sample.color}" unless @player
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

def old_params
  return {} unless request.referer
  Rack::Utils.parse_nested_query(URI.parse(request.referer).query)
end

def current_player
  color = params['color'] || old_params['color'] 
  player = $game.players.detect{|p| p.color == color }
  _player = $game.players.detect{|p| p.color == color }
  player
end
