require 'sinatra'
require 'puma'
require 'json'
require 'pry'
require 'faye/websocket'
require_relative 'models/catan'
Dir.glob('./models/*.rb').each { |f| require f }

$connections_by_game = {}

class Catan
  class Server < Sinatra::Base
    before do
      if request.env['CONTENT_TYPE'] == 'application/json'
        params.merge!(JSON.parse(request.body.read))
      end
    end

    get '/' do
      @games = $connections_by_game.keys
      erb :games
    end

    post '/games' do
      new_game = Game.new(
        id: SecureRandom.uuid,
        side_length: new_game_param(:board_size),
        n_players: new_game_param(:n_players)
      )
      $connections_by_game[new_game] = []
      redirect_to new_game
    end

    get '/games/:id' do
      redirect '/' unless current_game
      redirect_to current_game unless current_player
      erb :game
    end

    get '/games/:id/board' do
      redirect '/' unless current_game
      redirect_to current_game unless current_player
      { html: erb(:board), data: current_game.as_json }.to_json
    end

    post '/games/:id/messages' do
      current_game.messages << [current_player.color, params['message']]
      broadcast('message', html: erb(:messages), data: current_game.as_json)
      erb :messages
    end

    post '/games/:id/actions' do
      data = params['data']
      data = JSON.parse(params['data']) if data.is_a?(String)

      begin
        current_game.perform_action(current_player, data['action'], data['args'])
        game_json = current_game.as_json
        board_html = erb(:board)
        message_html = erb(:messages)
        broadcast('action', html: board_html, data: game_json)
        broadcast('message', html: message_html, data: game_json)
        status 200
        { html: board_html, data: game_json }.to_json
      rescue CatanError => e
        body e.message
        status 400
      end
    end

    def redirect_to(game)
      redirect "/games/#{game.id}?color=#{game.players.sample.color}"
    end

    def current_game
      @game ||= $connections_by_game.keys.detect{|g| g.id == params['id'] }
    end

    def current_player
      @player ||= current_game && current_game.players.detect{|p| p.color == params['color']}
    end

    def broadcast(event, data)
      message = JSON.generate([event, data])
      $connections_by_game[current_game].each do |ws|
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
        game = $connections_by_game.keys.detect { |g| g.id == env['REQUEST_PATH'][UUID_REGEX] }
        ws.on :open do |event|
          $connections_by_game[game] << ws
          ws.send(JSON.generate(['action', data: game.as_json]))
        end
        ws.on :close do |event|
          $connections_by_game[game].delete(ws)
          ws = nil
        end
        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end
