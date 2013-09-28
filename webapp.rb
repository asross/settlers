require 'sinatra'
require 'em-websocket'
require 'thin'
require 'json'
require 'pry'
require_relative 'models/catan'
Dir.glob('./models/*.rb').each { |f| require f }

$game = Game.new
$channel = EM::Channel.new

EM.run do
  class App < Sinatra::Base
    get '/' do
      @game = $game
      redirect "/?color=#{$game.players.sample.color}" unless current_player
      erb :game
    end

    post '/messages' do
      @game = $game
      $game.messages << [current_player.color, params['message']]
      $channel.push JSON.generate(['message', { html: erb(:messages) }])
      redirect request.referer
    end

    post '/actions' do
      @game = $game
      data = JSON.parse(params[:data])
      begin
        $game.perform_action(current_player, data['action'], data['args'])
        $channel.push JSON.generate(['action', { html: erb(:board) }])
        status 200
      rescue CatanError => e
        body e.message
        status 400
      end
    end

    def current_player
      @current_player ||= $game.players.detect{|p| p.color == params['color']}
    end
  end

  EM::WebSocket.start(host: '0.0.0.0', port: 8080) { |ws|
    ws.onopen {
      sid = $channel.subscribe { |msg| ws.send msg }

      ws.onclose {
        $channel.unsubscribe(sid)
      }
    }
  }

  Thin::Server.start(App, '0.0.0.0', 4567)
end
