# encoding: utf-8

COLOR_CODES = {
  'desert' => 39,
  'wheat' => 33,
  'brick' => 31,
  'sheep' => 92,
  'ore' => 37,
  'wood' => 32,
  'water' => 34,

  'lightcoral' => 31,
  'lawngreen' => 32,
  'gold' => 33,
  'azure' => 34,
  'thistle' => 35,
  'aqua' => 36,
}

BG_COLOR_CODES = {
  'lightcoral' => '1;97;41',
  'lawngreen' => '1;97;42',
  'gold' => '1;97;43',
  'azure' => '1;97;44',
  'thistle' => '1;97;45',
  'aqua' => '1;97;46',
}

NUMBER_CHARS = " ①②③④⑤⑥⑦⑧⑨⑩⑪⑫"

def paint(color, text)
  colorize(text, COLOR_CODES[color])
end

def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

class String
  def cjust(n, padder, pad_at_start=true)
    if length >= n
      return self
    else
      new_string = (pad_at_start ? "#{padder}#{self}" : "#{self}#{padder}")
      new_string.cjust(n, padder, !pad_at_start)
    end
  end
end

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
    paint(hex.type, text)
  end

  def no
    color NUMBER_CHARS[hex.number].rjust 2
  end

  def re
    color(hex.type.rjust 5)
  end

  def coords
    color("#{hex.x},#{hex.y}")
  end

  def hex_lines
    bl = (botleft == '  ' ? " #{bottom}" : botleft)
    br = (botright == '  ' ? "#{bottom} " : botright)
    if bottom != '_'
      if botright == '  ' && botleft == '  '
        bo = bottom*3
      elsif botright == '  '
        bo = " #{bottom}#{bottom}"
      elsif botleft == '  '
        bo = "#{bottom}#{bottom} "
      else
        bo = " #{bottom} "
      end
    else
      bo = bottom*3
    end
    lb = leftbot
    lt = lefttop
    if hex.type == 'water'
      if hex.port_type
        l1 = " #{lt} #{color("~~~~~")} "
        l2 = "#{lt} #{color("~#{hex.port_type[0..4].cjust(5, '~')}~")}"
        l3 = "#{lb}  #{color("~~~~~")} "
        l4 = " #{lb}#{bl}#{bo}#{br}"
        case hex.port_direction
        when 'botleft' then l2[7] = "*" and l3[8] = "*"
        when 'bottom' then l3[8] = "*" and l3[12] = "*"
        when 'top' then l1[8] = "*" and l1[12] = "*"
        when 'topright' then l1[12] = "*" and l2[13] = "*"
        when 'topleft' then l1[8] = "*" and l2[7] = "*"
        when 'botright' then l2[13] = "*" and l3[12] = "*"
        end
      else
        l1 = " #{lt} #{color("~~~~~")} "
        l2 = "#{lt} #{color("~~~~~~~")}"
        l3 = "#{lb}  #{color("~~~~~")} "
        l4 = " #{lb}#{bl}#{bo}#{br}"
      end
    elsif hex.type == 'desert'
      l1 = " #{lt}  #{coords}  "
      l2 = "#{lt}  #{color('desert')}"
      l3 = "#{lb}        "
      l3 = "#{lb}    #{colorize("R", "1;97;40")}   " if hex.robbed
      l4 = " #{lb}#{bl}#{bo}#{br}"
    elsif hex.robbed
      l1 = " #{lt}  #{coords}  "
      l2 = "#{lt}  #{re} "
      l3 = "#{lb}    #{colorize("R", "1;97;40")}   "
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

def print_dev_card(card)
  s = card.type
  s = "#{s} (used)" if card.played
  s
end

def print_game(game, current_player)
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
    sym = colorize("⌂#{city.size}", BG_COLOR_CODES[city.color])

    if y0 + y1 + y2 - 3*[y0,y1,y2].min == 2 # bottom left
      i = [y0,y1,y2].index([y0,y1,y2].min)
      hex_attributes[city.hexes[i].x][city.hexes[i].y].botleft = sym
    else # bottom right
      i = [x0+y0,x1+y1,x2+y2].index([x0+y0,x1+y1,x2+y2].min)
      hex_attributes[city.hexes[i].x][city.hexes[i].y].botright = sym
    end
  end
  roads.each do |road|
    y0 = road.hexes[0].y; x0 = road.hexes[0].x
    y1 = road.hexes[1].y; x1 = road.hexes[1].x

    if x0 == x1 # bottom
      i = [y0, y1].index([y0, y1].min)
      hex_attributes[road.hexes[i].x][road.hexes[i].y].bottom = colorize('_', BG_COLOR_CODES[road.color])
    elsif y0 == y1 # lefttop
      i = [x0, x1].index([x0, x1].max)
      hex_attributes[road.hexes[i].x][road.hexes[i].y].lefttop = colorize('/', BG_COLOR_CODES[road.color])
    else # leftbot
      i = [y0, y1].index([y0, y1].min)
      hex_attributes[road.hexes[i].x][road.hexes[i].y].leftbot = colorize('\\', BG_COLOR_CODES[road.color])
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
    all_lines[i+=1] += paint(p.color, "#{'*' if game.active_player == p.color}#{p.color}#{' (you)' if current_player == p.color}")
    all_lines[i+=1] += paint(p.color, "resources: #{p.color == current_player ? p.resource_cards : p.resource_cards.count}")
    all_lines[i+=1] += paint(p.color, "dev cards: #{p.color == current_player ? p.development_cards.map(&method(:print_dev_card)) : p.development_cards.count}")
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
