require 'sinatra'
require 'pry'
Dir.glob('./models/*.rb').each { |f| require f }

$game = Game.new

get '/' do
  @game = $game
  @board = @game.board
  @messages = @game.messages
  @player = @game.players.sample
  erb :board
end

post '/messages' do
  if params['message'].to_s.size > 0
    $game.messages.unshift params['message']
  end
  redirect '/'
end
