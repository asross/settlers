require_relative './catan_server.rb'

EM.run do
  EM::WebSocket.start(host: '0.0.0.0') { |ws|
    ws.onopen {
      sid = $channel.subscribe { |msg| ws.send msg }

      ws.onclose {
        $channel.unsubscribe(sid)
      }
    }
  }

  if ENV['PORT']
    Thin::Server.start(CatanServer, '0.0.0.0', ENV['PORT'])
  else
    Thin::Server.start(CatanServer, '0.0.0.0')
  end
end
