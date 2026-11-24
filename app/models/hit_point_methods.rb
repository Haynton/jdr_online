# The registry of the ways to get the hit points of the levels after the first (character_fields.hit_point_methods of
# a template): the average of the hit die, or a roll of it. One class per way in app/models/hit_point_methods. Like the
# ways to get the scores (AbilityMethods), a template lists those it offers (type, label and help in the words of the
# game), and the table picks one or leaves it to the player (TableRules). A new way: its class, its line in ALL
module HitPointMethods
  ALL = [HitPointMethods::Average, HitPointMethods::Roll].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  def self.find(key)
    all.find { |method| method.key == key }
  end
end
