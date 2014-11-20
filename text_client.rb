APP_URL = ENV['APP_URL'] || 'http://localhost:4567'
WS_URL = ENV['WS_URL'] || 'ws://localhost:8080'

require 'pry'
require 'json'
require 'faye/websocket'
require 'eventmachine'

require_relative './textbased'
require_relative './lib/promise'

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

def print_state(msg='')
  puts `clear`
  puts "\e[H\e[2J"
  puts msg
  puts "COLOR: #{$color}"
  puts "LAST ROLL: #{$game.last_roll}"
  print_board($game.board, $game.board.size)
  puts "available actions: #{$game.available_actions[$color]}"
  print 'say, do, or be: '
end

def say(arg1, *_)
  `curl -X POST -d "message=#{arg1}&color=#{$color}" #{APP_URL}/messages`
end
def do(arg1, arg2)
  json = "{\"data\":{\"action\":#{arg1.inspect},\"args\":#{arg2 || []}},\"color\":#{$color.inspect}}"
  `curl -XPOST -H 'Content-Type: application/json' -d '#{json}' #{APP_URL}/actions`
end
def be(arg1, *_)
  colors = $game.players.map(&:color)
  if colors.include?(arg1)
    $color = arg1
  else
    raise "invalid color #{arg1}; valid choices are #{colors}"
  end
end

def game_loop(msg = '')
  print_state(msg)
  promise = Promise.new { |fulfill|
    fulfill.call(gets.chomp)
  }.then(->(value) {
    Promise.new { |fulfill|
      send(*value.split('|').map(&:strip))
      fulfill.call
    }.then(->(*__) { game_loop },
           ->(err) { game_loop(err) })
  })
end

EM.run {
  ws = Faye::WebSocket::Client.new(WS_URL)

  ws.onopen = lambda do |event|
    p [:open]
  end

  ws.onmessage = lambda do |event|
    first_time = $game.nil?
    $game = NestedHashie.new(JSON.parse(event.data).last['data'])
    $color ||= $game.players.map(&:color).sample

    if first_time
      game_loop
    else
      print_state
    end
  end

  ws.onclose = lambda do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
