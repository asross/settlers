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
    $game = Game.new(side_length: new_game_param(:board_size), n_players: new_game_param(:n_players))
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

  def new_game_param(param)
    value = params[:game][param]
    return [[value.to_i, 2].max, 20].min if value && value != ''
    raise
  rescue
    3
  end
end

unless ENV['APP_ENV'] == 'test'
  EM.run do
    EM::WebSocket.start(host: '0.0.0.0', port: 8080) { |ws|
      ws.onopen {
        sid = $channel.subscribe { |msg| ws.send msg }

        $channel.push JSON.generate(['action', { data: $game.as_json }])

        ws.onclose {
          $channel.unsubscribe(sid)
        }
      }
    }

    Thin::Server.start(CatanServer, '0.0.0.0', 4567)
  end
end
