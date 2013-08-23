Dir.glob('./models/*.rb').each { |f| require f }
require 'minitest'
require 'minitest/pride'
require 'minitest/autorun'
require 'pry'

def raises(msg, &block)
  error = assert_raises(RuntimeError, &block)
  error.message.must_match /#{msg}/
end
