require_relative '../catan_server.rb'
require 'minitest'
require 'minitest/pride'
require 'minitest/autorun'
require 'pry'
require 'capybara'
require 'capybara_minitest_spec'

class Minitest::Test
  include Capybara::DSL

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

Capybara.app = CatanServer

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

def ensure_robbed(x, y)
  return unless @board
  @board.robbed_hex.robbed = false
  h(x, y).robbed = true
end
