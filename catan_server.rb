require 'sinatra'
require 'em-websocket'
require 'thin'
require 'json'
require 'pry'
require_relative 'models/catan'
Dir.glob('./models/*.rb').each { |f| require f }

side_length = ENV.fetch('SIDE_LENGTH', 3).to_i
n_players = ENV.fetch('PLAYERS', 3).to_i
$game = Game.new(side_length: side_length, n_players: n_players)
$channel = EM::Channel.new

class CatanServer < Sinatra::Base
  before do
    @game = $game
  end

  get '/' do
    redirect "/?color=#{@game.players.sample.color}" unless current_player
    erb :game
  end

  post '/messages' do
    @game.messages << [current_player.color, params['message']]
    broadcast('message', html: erb(:messages))
    redirect request.referer
  end

  post '/actions' do
    data = JSON.parse(params[:data])
    begin
      @game.perform_action(current_player, data['action'], data['args'])
      broadcast('action', html: erb(:board))
      status 200
    rescue CatanError => e
      body e.message
      status 400
    end
  end

  def current_player
    @current_player ||= @game.players.detect{|p| p.color == params['color']}
  end

  def broadcast(event, data)
    $channel.push JSON.generate([event, data])
  end
end
