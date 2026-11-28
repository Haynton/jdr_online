# The registry of the ways to equip a character created above level 1 (character_fields.higher_level_equipment_methods
# of a template, decision of 27 November): by the tiers of levels the template declares (SRD 5.2.1 « Starting
# Equipment at Higher Levels »: gold and magic items more each tier), or the normal starting equipment only. Like the
# other rules of the table (TableRules), a template lists those it offers, the table picks one (the first while none
# is picked). A new way: its class, its line in ALL
module HigherLevelEquipmentMethods
  ALL = [HigherLevelEquipmentMethods::ByLevel, HigherLevelEquipmentMethods::NormalOnly].freeze

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
