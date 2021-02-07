require_relative '../test_helper'

describe Hex do
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
        _(hex.adjacent?(neighbor)).must_equal true
        _(neighbor.adjacent?(hex)).must_equal true
      end

      strangers.each do |stranger|
        _(hex.adjacent?(stranger)).must_equal false
        _(stranger.adjacent?(hex)).must_equal false
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

      _(hex.directions['top']).must_equal top.coordinates
      _(hex.directions['bottom']).must_equal bottom.coordinates
      _(hex.directions['topleft']).must_equal topleft.coordinates
      _(hex.directions['botleft']).must_equal bottomleft.coordinates
      _(hex.directions['topright']).must_equal topright.coordinates
      _(hex.directions['botright']).must_equal bottomright.coordinates

      hex.port_direction = 'top'
      _(hex.port_borders?(settle(hex, top, topleft))).must_equal true
      _(hex.port_borders?(settle(hex, top, topright))).must_equal true
      _(hex.port_borders?(settle(hex, topleft, bottomleft))).must_equal false

      hex.port_direction = 'bottom'
      _(hex.port_borders?(settle(hex, bottom, bottomleft))).must_equal true
      _(hex.port_borders?(settle(hex, bottom, bottomright))).must_equal true
      _(hex.port_borders?(settle(hex, topleft, bottomleft))).must_equal false
    end
  end
end
