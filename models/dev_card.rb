class DevCard < Catan
  TYPES = %w(monopoly road_building year_of_plenty knight victory_point).map(&:to_sym)
  attr_accessor :type, :played

  def initialize(type)
    @type = type
    @played = false
  end

  def played?
    @played
  end

  def playable?
    !played? && type != :victory_point
  end

end
