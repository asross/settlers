game_url = ENV['HOST'] || fail("must pass HOST")
GAME_URL = game_url.sub('localhost', '0.0.0.0')
WS_URL = ENV['WS_URL'] || GAME_URL.sub(/^http/, 'ws')
if ENV['PLAYER'].to_s.length > 0
  $color = ENV['PLAYER']
end

require 'pry'
require 'json'
require 'faye/websocket'
require 'eventmachine'
require_relative './deep_open_struct'
require_relative './game_printer'
require 'net/http'
require 'readline'

Readline.completion_append_character = " "

def set_completions(list)
  Readline.completion_proc = proc { |s| list.grep(/^#{Regexp.escape(s)}/) }
end

def print_state(msg='')
  puts `clear`
  puts "\e[H\e[2J"
  puts "#{msg}\n" if msg.to_s.length > 0
  puts "LAST ROLL: #{$game.last_roll}" if $game.last_roll
  print_game($game, $color)
  puts "available actions: #{$game.available_actions[$color]}"
end

def say(*msg_parts)
  Net::HTTP.post_form(URI("#{GAME_URL}/messages"),
    color: $color,
    message: msg_parts.join(' ')
  )
end

def _do(action, args=nil)
  response = Net::HTTP.post_form(URI("#{GAME_URL}/actions"),
    color: $color,
    data: {
      'action' => action,
      'args' => JSON.parse(args||'[]')
    }.to_json
  )

  if response.code =~ /^4/
    raise response.body
  elsif response.code =~ /^5/
    raise "Internal server error"
  end
end

def be(arg1, *)
  colors = $game.players.map(&:color)
  unless colors.include?(arg1)
    raise "invalid color #{arg1}; valid choices are #{colors}"
  end
  $color = arg1
end

def game_loop
  loop do
    set_completions(%w(say do be) + $game.players.map(&:color) + $game.available_actions[$color])
    input = Readline.readline('say, do, or be: ', true)
    next unless input.length > 0
    action, *args = input.split.map(&:strip)

    begin
      case action
      when 'do' then _do(*args)
      when 'say' then say(*args)
      when 'be' then be(*args); print_state
      else raise "must start with 'do', 'say', or 'be'"
      end
    rescue => e
      print_state(e.message)
    end
  end
end

EM.run {
  ws = Faye::WebSocket::Client.new(WS_URL)

  ws.on :message do |event|
    first_time = $game.nil?
    $game = DeepOpenStruct.new(JSON.parse(event.data).last['data'])
    $color ||= $game.players.map(&:color).sample
    set_completions(%w(say do be) + $game.players.map(&:color) + $game.available_actions[$color])

    print_state

    if first_time
      Thread.new { game_loop }
    else
      print 'say, do, or be: '
    end
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end
}
