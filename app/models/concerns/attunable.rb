# The magic of an item of the inventory (decision of 27 November, SRD 5.2.1): what its catalog entry gives the rules (a
# magic bonus to attack and damage or to the armour class, a bonus to the armour class, an ability set to a score)
# counts only once its character is attuned to it, when it requires attunement (attunement: true); a few items at a
# time, as many as the template says (character_fields.attunement: limit). Part of InventoryItem
module Attunable
  extend ActiveSupport::Concern

  # The values of an item the rules read as its magic
  MAGIC_FIELDS = %w[magic_bonus item_ac_bonus sets_ability sets_ability_score].freeze

  def requires_attunement?
    properties["attunement"] == true
  end

  def magic_active?
    !requires_attunement? || attuned
  end

  # Its bonus to attack and damage (a weapon) or to the armour class (an armour, a shield), 0 while not attuned
  def magic_bonus
    magic_active? ? properties["magic_bonus"].to_i : 0
  end

  # Its values for the rules: without its magic while it waits for its attunement
  def rule_properties
    magic_active? ? properties : properties.except(*MAGIC_FIELDS)
  end

  # Attunes the character to it, or ends it; nil once done, :too_many past the limit of the template
  def attune(attuned_now, limit:)
    return :too_many if attuned_now && limit && others_attuned >= limit

    update!(attuned: attuned_now)
    nil
  end

  private

  def others_attuned
    character.inventory_items.where(attuned: true).where.not(id: id).count
  end
end
