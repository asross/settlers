require 'sinatra'
require 'pry'
Dir.glob('./models/*.rb').each { |f| require f }

$messages = []
$board = Board.create(3)

get '/' do
  @messages = $messages
  @board = $board
  erb :board
end

post '/messages' do
  if params['message'].to_s.size > 0
    $messages.unshift params['message']
  end
  redirect '/'
end
