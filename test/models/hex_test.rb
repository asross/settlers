require_relative '../test_helper'

describe Hex do
  it 'should be able to run tests' do
    1.must_equal 1
  end

  def create_hex(x, y)
    Hex.new(x, y, nil, nil, nil)
  end

  def settle(h1, h2, h3)
    Settlement.new(h1, h2, h3, nil)
  end

  describe '#adjacent?' do
    it 'is adjacent to six other hexes' do
      hex = create_hex(3,2)

      top = create_hex(3,1)
      bottom = create_hex(3,3)
      topleft = create_hex(2,2)
      bottomleft = create_hex(2,3)
      topright = create_hex(4,1)
      bottomright = create_hex(4,2)

      faraway1 = create_hex(3,4)
      faraway2 = create_hex(4,3)

      neighbors = [top, bottom, topleft, bottomleft, topright, bottomright]
      strangers = [faraway1, faraway2]

      neighbors.each do |neighbor|
        hex.adjacent?(neighbor).must_equal true
        neighbor.adjacent?(hex).must_equal true
      end

      strangers.each do |stranger|
        hex.adjacent?(stranger).must_equal false
        stranger.adjacent?(hex).must_equal false
      end
    end
  end

  describe '#directions and #port_borders' do
    it 'correctly determines which hexes/settlements are in which directions' do
      hex = create_hex(3,2)

      top = create_hex(3,1)
      bottom = create_hex(3,3)
      topleft = create_hex(2,2)
      bottomleft = create_hex(2,3)
      topright = create_hex(4,1)
      bottomright = create_hex(4,2)

      hex.directions['top'].must_equal top.coordinates
      hex.directions['bottom'].must_equal bottom.coordinates
      hex.directions['topleft'].must_equal topleft.coordinates
      hex.directions['botleft'].must_equal bottomleft.coordinates
      hex.directions['topright'].must_equal topright.coordinates
      hex.directions['botright'].must_equal bottomright.coordinates

      hex.port_direction = 'top'
      hex.port_borders?(settle(hex, top, topleft)).must_equal true
      hex.port_borders?(settle(hex, top, topright)).must_equal true
      hex.port_borders?(settle(hex, topleft, bottomleft)).must_equal false

      hex.port_direction = 'bottom'
      hex.port_borders?(settle(hex, bottom, bottomleft)).must_equal true
      hex.port_borders?(settle(hex, bottom, bottomright)).must_equal true
      hex.port_borders?(settle(hex, topleft, bottomleft)).must_equal false
    end
  end
end
