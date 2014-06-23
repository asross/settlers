APP_URL = ENV['APP_URL'] || 'http://localhost:4567'
WS_URL = ENV['WS_URL'] || 'ws://localhost:8080'

require 'pry'
require 'json'
require 'faye/websocket'
require 'eventmachine'

require_relative './textbased'

class NestedArray
  attr_reader :array
  def initialize(array)
    @array = array.map do |el|
      case el
      when Array then NestedArray.new(el).array
      when Hash then NestedHashie.new(el)
      else el
      end
    end
  end
end

class NestedHashie
  def initialize(hash)
    @h = hash
  end

  def method_missing(method, *args)
    if @h.has_key?(method.to_s)
      result = @h[method.to_s]
      result = NestedHashie.new(result) if result.is_a?(Hash)
      result = NestedArray.new(result).array if result.is_a?(Array)
      result
    else
      @h.send(method, *args)
    end
  end
end

class NilClass
  def any?
    false
  end
end

EM.run {
  ws = Faye::WebSocket::Client.new(WS_URL)

  ws.onopen = lambda do |event|
    p [:open]
  end

  ws.onmessage = lambda do |event|
    `clear`
    $game = NestedHashie.new(JSON.parse(event.data).last['data'])
    $color = $game.players.map(&:color).sample unless $color
    puts "COLOR: #{$color}"
    puts "LAST ROLL: #{$game.last_roll}"
    print_board($game.board, $game.board.size)
  end

  ws.onclose = lambda do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end

  Thread.new {
    while true
      while $game && (actions = $game.available_actions[$color]).any?
        if $input
          puts "would be choosing #{actions[$input.to_i]}"
          $input = nil
          $getting = false
          break
        elsif $getting
          sleep 0.01
        else
          $getting = true
          actions.each_with_index { |action, i| puts "#{i}: #{action}" }
          print 'choose: '
          Thread.new { $input = gets }
        end
      end
      sleep 0.01
    end
  }
}
