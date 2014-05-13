class DevCard < Catan
  TYPES = %w(monopoly road_building year_of_plenty knight victory_point).map(&:to_sym)

  TYPES.each do |type|
    class_eval <<-RUBY
      def #{type}?
        type.to_s == "#{type}"
      end
    RUBY
  end

  attr_accessor :type, :played, :turn_purchased

  def initialize(type)
    @type = type.to_sym
    @played = false
  end

  def playable_on_turn?(turn)
    return false if victory_point?
    return false if turn == turn_purchased
    return false if played
    true
  end

  def unplayed?
    !played
  end

end
