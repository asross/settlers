class DevCard < Catan
  TYPES = %w(monopoly road_building year_of_plenty knight victory_point).map(&:to_sym)
  attr_accessor :type, :played, :turn_purchased

  def initialize(type)
    @type = type.to_sym
    @played = false
  end

  def playable_on_turn?(turn)
    return false if type == :victory_point
    return false if turn == turn_purchased
    return false if @played
    true
  end

end
