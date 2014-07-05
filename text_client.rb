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

  # say message
  # do action arguments
  # be color

  Thread.new {
    while true
      while $game && $color
        if $input
          type, arg1, arg2 = $input.split('|').map(&:strip)
          $input = nil
          $getting = false
          begin
          case type
          when 'say'
            `curl -X POST -d "message=#{arg1}&color=#{$color}" #{APP_URL}/messages`
          when 'do'
            json = "{\"data\":{\"action\":#{arg1.inspect},\"args\":#{arg2 || []}},\"color\":#{$color.inspect}}"
            command = "curl -XPOST -H 'Content-Type: application/json' -d '#{json}' #{APP_URL}/actions"
            puts command
            system command
            sleep 0.1
          when 'be'
            colors = $game.players.map(&:color)
            if colors.include?(arg1)
              $color = arg1
            else
              puts "invalid color #{arg1}; valid choices are #{colors}"
            end
          end
          rescue => e
            puts e.message
          end
          break
        elsif $getting
          sleep 0.01
        else
          $getting = true
          puts "available actions: #{$game.available_actions[$color]}"
          print 'say, do, or be: '
          Thread.new { $input = gets.chomp }
        end
      end
      sleep 0.01
    end
  }
}
