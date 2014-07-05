require 'sinatra'
require 'em-websocket'
require 'thin'
require 'json'
require 'pry'
require_relative 'models/catan'
Dir.glob('./models/*.rb').each { |f| require f }

$game = Game.new(side_length: ENV.fetch('SIZE', 3).to_i,
                 n_players: ENV.fetch('PLAYERS', 3).to_i)
$channel = EM::Channel.new

class CatanServer < Sinatra::Base
  before do
    @game = $game
    if request.env['CONTENT_TYPE'] == 'application/json'
      params.merge!(JSON.parse(request.body.read))
    end
  end

  post '/new_game' do
    board_size = (params[:game][:board_size] || 3).to_i
    n_players = (params[:game][:n_players] || 3).to_i
    $game = Game.new(side_length: board_size, n_players: n_players)
    redirect '/'
  end

  get '/' do
    redirect "/?color=#{@game.players.sample.color}" unless current_player
    erb :game
  end

  post '/messages' do
    @game.messages << [current_player.color, params['message']]
    broadcast('message', html: erb(:messages), data: @game.as_json)
  end

  post '/actions' do
    data = params['data']
    data = JSON.parse(params['data']) if data.is_a?(String)

    begin
      @game.perform_action(current_player, data['action'], data['args'])
      broadcast('action', html: erb(:board), data: @game.as_json)
      broadcast('message', html: erb(:messages), data: @game.as_json)
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
