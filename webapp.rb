require 'sinatra'
require 'pry'
Dir.glob('./models/*.rb').each { |f| require f }

$game = Game.new

before do
  @game = $game
  @color = params['color'] || old_params['color']
  @player = @game.players.detect{|p| p.color == @color }
  redirect "?color=#{@game.players.sample.color}" unless @player
end

get '/' do
  @board = @game.board
  @messages = @game.messages
  erb :board
end

post '/messages' do
  @game.messages << [@color, params['message']] if params['message'].to_s.size > 0
  redirect request.referer
end

def old_params
  return {} unless request.referer
  Rack::Utils.parse_nested_query(URI.parse(request.referer).query)
end
