# The registry of the ways to get the scores of the abilities of a new character (character_fields.ability_methods of
# a template): roll dice, place a standard array, buy them with points. One class per method in
# app/models/ability_methods.
# A template lists the methods it offers, each with its type (a key of this registry), its label and help in the words
# of the game, and the settings of its type (its dice, its values, its points). The table picks one, or lets the player
# pick (GameTable#ability_method). A new method: its class, its line in ALL
module AbilityMethods
  ALL = [AbilityMethods::Roll, AbilityMethods::StandardArray, AbilityMethods::PointBuy].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  # The method of that key, nil for a key the registry does not know
  def self.find(key)
    all.find { |method| method.key == key }
  end
end
