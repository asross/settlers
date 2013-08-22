Dir.glob('./models/*.rb').each { |f| require f }
require 'minitest'
require 'minitest/autorun'
require 'pry'
