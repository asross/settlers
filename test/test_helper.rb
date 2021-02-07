ENV['APP_ENV'] = 'test'
require_relative '../server.rb'
ENV['RELOAD_AFTER_ACTIONS'] = '1'
require 'minitest'
require 'minitest/pride'
require 'minitest/autorun'
require 'pry'
require 'capybara/dsl'
require 'capybara_minitest_spec'

class Minitest::Test
  include Capybara::DSL

  def teardown
    Capybara.reset_sessions!
    Capybara.use_default_driver
  end
end

Capybara.app = Catan::Server

def raises(msg, &block)
  error = assert_raises(CatanError, &block)
  _(error.message).must_match /#{msg}/
end

def assert_similar(array1, array2)
  _((array1 - array2)).must_equal []
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
