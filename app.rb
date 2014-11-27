require_relative './catan_server.rb'

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
