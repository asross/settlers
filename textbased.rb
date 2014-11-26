#2 situations for settlements:
#settlement should go to bottom left
#   true iff y, y+1, y+1 -- goes on bottom of y
#settlement should go to bottom right
#   true iff y, y, y+1 --- goes on bottom of y with minimum x
#
GRAY = "1;90"
RED = 31
GREEN = 32
DARKGREEN = "1;32"
LIGHTGREEN = 92
YELLOW = "1;33"
BLUE = 34
THISTLE = 35
AQUA = 36

COLOR_MAP = {
  'desert' => 39,
  'wheat' => YELLOW,
  'brick' => RED,
  'sheep' => GREEN,
  'ore' => GRAY,
  'wood' => DARKGREEN,
  'water' => BLUE,
  'aqua' => AQUA,
  'gold' => YELLOW,
  'lightcoral' => RED,
  'azure' => BLUE,
  'lawngreen' => LIGHTGREEN,
  'thistle' => THISTLE
}

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def aqua(text); colorize(text, 36); end
def thistle(text); colorize(text, THISTLE); end
def gold(text); colorize(text, YELLOW); end
def lightcoral(text); red(text); end
def azure(text); blue(text); end
def lawngreen(text); colorize(text, LIGHTGREEN); end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, "1;33"); end
def blue(text); colorize(text, 34); end
def darkgreen(text); colorize(text, "1;32"); end
def bold(text); colorize(text, "1;30"); end

class HexDecorator
  attr_reader :hex
  attr_accessor :botleft, :botright, :bottom, :leftbot, :lefttop
  def initialize(hex)
    @hex = hex
    @botleft = "  "
    @botright = "  "
    @bottom = "_"
    @leftbot = "\\"
    @lefttop = "/"
  end

  def color(text)
    colorize(text, COLOR_MAP[hex.type])
  end

  def no
    color(hex.number.to_s.ljust 2)
  end

  def re
    color(hex.type.rjust 5)
  end

  def coords
    color("#{hex.x},#{hex.y}")
  end

  def hex_lines
    bl = botleft
    br = botright
    bo = "#{bottom} #{bottom}"
    lb = leftbot
    lt = lefttop
    if hex.type == 'water'
      if hex.port_type
        l1 = " #{lt} #{blue("~~~~~")} "
        l2 = "#{lt} #{blue("~#{hex.port_type[0..4].ljust(5, '~')}~")}"
        l3 = "#{lb}  #{blue("~~~~~")} "
        l4 = " #{lb}#{bl}#{bo}#{br}"
      else
        l1 = " #{lt} #{blue("~~~~~")} "
        l2 = "#{lt} #{blue("~~~~~~~")}"
        l3 = "#{lb}  #{blue("~~~~~")} "
        l4 = " #{lb}#{bl}#{bo}#{br}"
      end
    elsif hex.type == 'desert'
      l1 = " #{lt} des-  "
      l2 = "#{lt}    ert "
      l3 = "#{lb}    #{coords} "
      l4 = " #{lb}#{bl}#{bo}#{br}"
    elsif hex.robbed
      l1 = " #{lt}  #{coords}  "
      l2 = "#{lt}  #{re} "
      l3 = "#{lb}    #{colorize("R", "1;37;40")}   "
      l4 = " #{lb}#{bl}#{bo}#{br}"
    else
      l1 = " #{lt}  #{coords}  "
      l2 = "#{lt}  #{re} "
      l3 = "#{lb}   #{no}   "
      l4 = " #{lb}#{bl}#{bo}#{br}"
    end

    [l1, l2, l3, l4]
  end
end

def print_board(game, current_player)
  board = game.board
  size = board.size
  hexes = board.hexes
  cities = board.settlements
  roads = board.roads
  # initialize what we're going to print
  all_lines = Array.new(6*size+4)
  for x in 0..all_lines.length-1
    all_lines[x] = ""
    if x >= 4*size
      all_lines[x] += "         "*((x-4*size)/2 + 1)
    end
  end
  # and now for some horrible looking code that figures out where to place the settlements
  hex_attributes = hexes.map { |row| row.map { |hex| HexDecorator.new(hex) } }

  cities.each do |city|
    y0 = city.hexes[0].y; x0 = city.hexes[0].x
    y1 = city.hexes[1].y; x1 = city.hexes[1].x
    y2 = city.hexes[2].y; x2 = city.hexes[2].x
    sym = send(city.color, "#{city.color.capitalize[0]}#{city.size}")
    if y0 + y1 + y2 - 3*[y0,y1,y2].min == 2
      # put it on the bottom left
      i = [y0,y1,y2].index([y0,y1,y2].min)
      hex_attributes[city.hexes[i].x][city.hexes[i].y].botleft = sym
    else
      # put it on the bottom right
      i = [x0+y0,x1+y1,x2+y2].index([x0+y0,x1+y1,x2+y2].min)
      hex_attributes[city.hexes[i].x][city.hexes[i].y].botright = sym
    end
  end
  for road in roads
    y0 = road.hexes[0].y; x0 = road.hexes[0].x
    y1 = road.hexes[1].y; x1 = road.hexes[1].x
    sym = send(road.color, '^')

    if x0 == x1 # bottom
      i = [y0, y1].index([y0, y1].min)
      hex_attributes[road.hexes[i].x][road.hexes[i].y].bottom = sym
    elsif y0 == y1 # lefttop
      i = [x0, x1].index([x0, x1].max)
      hex_attributes[road.hexes[i].x][road.hexes[i].y].lefttop = sym
    else # leftbot
      i = [y0, y1].index([y0, y1].min)
      hex_attributes[road.hexes[i].x][road.hexes[i].y].leftbot = sym
    end
  end
  # go through all the hexes and print them
  for i in 0..size-1 #x
    for j in 0..size-1 #y
      hls = hex_attributes[i][j].hex_lines
      all_lines[2*i + 4*j] += hls[0]
      all_lines[2*i + 4*j+1] += hls[1]
      all_lines[2*i + 4*j+2] += hls[2]
      all_lines[2*i + 4*j+3] += hls[3]
    end
  end

  #max_length = all_lines.max_by(&:length).length

  all_lines.map!{|l| l.ljust(10*size+(l.length-l.gsub(/\e\[(\d+)(;\d+)*m/, '').length)) + '|  ' }

  i = 6
  game.players.each do |p|
    all_lines[i+=1] += send(p.color, "#{'*' if game.active_player == p.color}#{p.color}#{' (you)' if current_player == p.color}")
    all_lines[i+=1] += send(p.color, "resources: #{p.color == current_player ? p.resource_cards : p.resource_cards.count}")
    all_lines[i+=1] += send(p.color, "dev cards: #{p.color == current_player ? p.development_cards : p.development_cards.count}")
    i += 1
  end

  all_lines[i+=1] += "-- messages --"
  game.messages.reverse.take(10).each do |m|
    all_lines[i+=1] += [m].flatten.join(': ')
  end

  for x in 7..all_lines.length-15
    puts all_lines[x]
  end
  puts
end
