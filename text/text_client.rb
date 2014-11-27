APP_URL = ENV['APP_URL'] || 'http://localhost:4567'
WS_URL = ENV['WS_URL'] || 'ws://localhost:8080'

require 'pry'
require 'json'
require 'faye/websocket'
require 'eventmachine'
require_relative './textbased'

class DeepOpenStruct
  def initialize(hash)
    hash.each { |k, v| define_singleton_method(k) {
      instance_variable_get(:"@#{k}") || instance_variable_set(:"@#{k}", coerce(v))
    } }
  end

  def [](k)
    send(k)
  end

  def coerce(v)
    case v
    when Hash then DeepOpenStruct.new(v)
    when Array then v.map(&method(:coerce))
    else v
    end
  end
end

def print_state(msg='')
  puts `clear`
  puts "\e[H\e[2J"
  puts msg if msg.to_s.length > 0
  puts "LAST ROLL: #{$game.last_roll}" if $game.last_roll
  print_board($game, $color)
  puts "available actions: #{$game.available_actions[$color]}"
  print 'say, do, or be: '
end

def say(arg1, *_)
  `curl -X POST -d "message=#{arg1}&color=#{$color}" #{APP_URL}/messages`
end

def do(arg1, arg2=[])
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

def game_loop
  loop do
    begin
      send(*gets.chomp.split.map(&:strip))
    rescue => e
      puts e.message
    end
    print_state
  end
end

EM.run {
  ws = Faye::WebSocket::Client.new(WS_URL)

  ws.onopen = lambda do |event|
    p [:open]
  end

  ws.onmessage = lambda do |event|
    first_time = $game.nil?
    $game = DeepOpenStruct.new(JSON.parse(event.data).last['data'])
    $color ||= $game.players.map(&:color).sample

    print_state
    Thread.new { game_loop } if first_time
  end

  ws.onclose = lambda do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
