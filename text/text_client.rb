APP_URL = ENV['APP_URL'] || 'http://localhost:4567'
WS_URL = ENV['WS_URL'] || 'ws://localhost:8080'

require 'pry'
require 'json'
require 'faye/websocket'
require 'eventmachine'
require_relative './deep_open_struct'
require_relative './game_printer'
require 'net/http'
require 'readline'

def print_state(msg='')
  puts `clear`
  puts "\e[H\e[2J"
  if msg.to_s.length > 0
    puts msg
    puts
  end
  puts "LAST ROLL: #{$game.last_roll}" if $game.last_roll
  print_game($game, $color)
  puts "available actions: #{$game.available_actions[$color]}"
end

def say(arg1, *_)
  Net::HTTP.post_form(URI("#{APP_URL}/messages"), message: arg1, color: $color)
  sleep 0.1
  false
end

def do(arg1, arg2=nil)
  response = Net::HTTP.post_form(URI("#{APP_URL}/actions"), data: { 'action' => arg1, 'args' => JSON.parse(arg2||'[]') }.to_json, color: $color)
  if response.code =~ /^4/
    raise response.body
  elsif response.code =~ /^5/
    raise "Internal server error"
  end
  sleep 0.1
  false
end

def be(arg1, *_)
  colors = $game.players.map(&:color)
  if colors.include?(arg1)
    $color = arg1
  else
    raise "invalid color #{arg1}; valid choices are #{colors}"
  end
  true
end

def game_loop
  loop do
    error_message = ''
    should_print = true
    begin
      input = Readline.readline('say, do, or be: ', true)
      if input.length > 0
        args = input.split.map(&:strip)
        raise "must start with 'do', 'say', or 'be'" unless %w(do say be).include?(args[0])
        should_print = send(*args)
      end
    rescue => e
      error_message = e.message
    end
    print_state(error_message) if should_print
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
