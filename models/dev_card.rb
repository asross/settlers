class DevCard < Catan
  TYPES = %w(monopoly road_building year_of_plenty knight victory_point).map(&:to_sym)

  DESCS = {
    monopoly: "When you play this card, announce 1 type of resource. All other players must give you all of their resources of that type.",
    year_of_plenty: "Take any 2 resources from the bank. Add them to your hand. They can be 2 of the same resource or 2 different resources.",
    victory_point: "This card counts as a victory point, but is hidden from other players! It will be revealed at the end of the game if you have at least 10 points.",
    knight: "Move the robber. Steal 1 resource from the owner of a settlement or city adjacent to the robber's new hex. If you have played at least 3 knights and more than any other player, you have the Largest Army, which counts as 2 victory points.",
    road_building: "Place 2 new roads as if you had just built them."
  }

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

  def as_json
    {
      type: type,
      played: played,
      turn_purchased: turn_purchased
    }
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
