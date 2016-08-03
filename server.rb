require 'sinatra'
require 'puma'
require 'json'
require 'pry'
require 'faye/websocket'
require_relative 'models/catan'
Dir.glob('./models/*.rb').each { |f| require f }

$games = {}

class Catan
  class Server < Sinatra::Base
    before do
      if request.env['CONTENT_TYPE'] == 'application/json'
        params.merge!(JSON.parse(request.body.read))
      end
    end

    get '/' do
      @games = $games.keys
      erb :games
    end

    post '/new_game' do
      new_game = Game.new(
        id: SecureRandom.uuid,
        side_length: new_game_param(:board_size),
        n_players: new_game_param(:n_players)
      )
      $games[new_game] = []
      redirect "/games/#{new_game.id}?color=#{new_game.players.sample.color}"
    end

    get '/games/:id' do
      @game =  $games.keys.detect { |game| game.id == params['id'] }
      redirect '/' unless @game
      redirect "/games/#{@game.id}?color=#{@game.players.sample.color}" unless current_player
      erb :game
    end

    post '/games/:id/messages' do
      @game = $games.keys.detect { |game| game.id == params['id'] }
      @game.messages << [current_player.color, params['message']]
      broadcast('message', html: erb(:messages), data: @game.as_json)
    end

    post '/games/:id/actions' do
      @game = $games.keys.detect { |game| game.id == params['id'] }
      data = params['data']
      data = JSON.parse(params['data']) if data.is_a?(String)

      begin
        @game.perform_action(current_player, data['action'], data['args'])
        broadcast('action', html: erb(:board), data: @game.as_json)
        broadcast('message', html: erb(:messages), data: @game.as_json)
        $games.delete(game) if @game.over?
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
      message = JSON.generate([event, data])
      $games[@game].each do |ws|
        ws.send(message) # TODO: customize message per color
      end
    end

    def new_game_param(param)
      value = params[:game][param]
      return [[value.to_i, 2].max, 20].min if value && value != ''
      raise
    rescue
      3
    end
  end

  class SocketMiddleware
    UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/

    def initialize(app)
      @app = app
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env)
        game = $games.keys.detect { |g| g.id == env['REQUEST_PATH'][UUID_REGEX] }
        ws.on :open do |event|
          $games[game] << ws
          ws.send(JSON.generate(['action', data: game.as_json]))
        end
        ws.on :close do |event|
          $games[game].delete(ws)
          ws = nil
        end
        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end
