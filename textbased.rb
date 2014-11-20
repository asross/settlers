#2 situations for settlements:
#settlement should go to bottom left
#   true iff y, y+1, y+1 -- goes on bottom of y
#settlement should go to bottom right
#   true iff y, y, y+1 --- goes on bottom of y with minimum x

class Hex_Attribute
  attr_accessor :botleft, :botright, :bottom, :leftbot, :lefttop
  def initialize()
    @botleft = "  "
    @botright = "  "
    @bottom = "_"
    @leftbot = "\\"
    @lefttop = "/"
  end 
end

#3 situations for roads:
#road should go on bottom
#    true iff x, x -- goes on bottom of minimum y
#road should go on top left
#    true iff y, y -- goes on topleft of maximum x
#road should go on bottom left
#    true otherwise -- goes on botleft of minimum y
def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end

def print_board(board, size)
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
  hex_attributes = Array.new(size) { Array.new(size) }
  for i in 0..size-1
    for j in 0..size-1
      hex_attributes[i][j] = Hex_Attribute.new()
    end
  end
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
    sym = send(road.color, road.color.downcase[0])
    y0 = road.hexes[0].y; x0 = road.hexes[0].x
    y1 = road.hexes[1].y; x1 = road.hexes[1].x
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
      hex = hexes[i][j]
      hls = hex_lines(hex.type, hex.number, hex.robbed, hex_attributes[i][j], i, j)
      all_lines[2*i + 4*j] += hls[0]
      all_lines[2*i + 4*j+1] += hls[1]
      all_lines[2*i + 4*j+2] += hls[2]
      all_lines[2*i + 4*j+3] += hls[3]
    end
  end
  for x in 3..all_lines.length-10
    puts all_lines[x]
  end
end

def aqua(text); colorize(text, 36); end
def thistle(text); colorize(text, 35); end
def gold(text); yellow(text); end
def lightcoral(text); red(text); end
def azure(text); blue(text); end
def lawngreen(text); colorize(text, 92); end

def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def yellow(text); colorize(text, "1;33"); end
def blue(text); colorize(text, 34); end
def darkgreen(text); colorize(text, "1;32"); end
def bold(text); colorize(text, "1;30"); end

def hex_lines(re, no, robbed, attributes, i, j)
  bl = attributes.botleft
  br = attributes.botright
  bo = "#{attributes.bottom} #{attributes.bottom}"
  lb = attributes.leftbot
  lt = attributes.lefttop
  if re == 'wheat'
    re = yellow(re)
  end
  if re == 'brick'
    re = red(re)
  end
  if re == 'sheep'
    re = green(re)
  end
  if re == 'ore'
    re = bold(' ore ')
  end
  if re == 'wood'
    re = darkgreen(' wood')
  end
  if re == 'water'
    l1 = " #{lt} #{blue("~~~~~")} "
    l2 = "#{lt} #{blue("~~~~~~~")}"
    l3 = "#{lb}  #{blue("~~~~~")} "
    l4 = " #{lb}#{bl}#{bo}#{br}"    
  elsif re == 'desert'
    l1 = " #{lt} des-  "
    l2 = "#{lt}    ert "
    l3 = "#{lb}  # #{i},#{j} "
    l4 = " #{lb}#{bl}#{bo}#{br}"  
  elsif robbed
    l1 = " #{lt}  #{i},#{j}  "
    l2 = "#{lt}  #{re} "
    l3 = "#{lb}    #{colorize("R", "1;37;40")}   "
    l4 = " #{lb}#{bl}#{bo}#{br}"    
  else
    if no < 10
      l1 = " #{lt}  #{i},#{j}  "
      l2 = "#{lt}  #{re} "
      l3 = "#{lb}   #{no}    "
      l4 = " #{lb}#{bl}#{bo}#{br}"
    else
      l1 = " #{lt}  #{i},#{j}  "
      l2 = "#{lt}  #{re} "
      l3 = "#{lb}   #{no}   "
      l4 = " #{lb}#{bl}#{bo}#{br}"
    end
  end
  return [l1, l2, l3, l4]
end
