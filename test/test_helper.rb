require_relative '../models/catan'
Dir.glob('./models/*.rb').each { |f| require f }
require 'minitest'
require 'minitest/pride'
require 'minitest/autorun'
require 'pry'

def raises(msg, &block)
  error = assert_raises(CatanError, &block)
  error.message.must_match /#{msg}/
end

def assert_similar(array1, array2)
  (array1 - array2).must_equal []
end

def h(x, y)
  return unless @board
  @board.hexes[x][y]
end
