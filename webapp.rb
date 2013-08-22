require 'sinatra'
require 'pry'
Dir.glob('./models/*.rb').each { |f| require_relative f }

$board = Board.create(3)

get '/' do
  @board = $board
  erb :board
end
