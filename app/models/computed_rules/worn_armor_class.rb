module ComputedRules
  # The armour class of what the character wears (decision of 26 November: worked out, the game master adds a bonus in
  # play). With an armour equipped: its base armour class plus the modifier of based_on (Dexterity), at most its cap
  # (none for a light armour, 2 for a medium one, 0 for a heavy one), plus the bonus of a fighting style while armoured
  # (Defense); without one: 10 plus that modifier, plus the
  # modifier of the unarmored defense of the class chosen in class_from (not for a monk with a shield:
  # unarmored_defense_without_shield). Then the bonus of the shield equipped, and
  # the number typed in bonus_from (the game master's). A plain number, kept as a text ("16"); nothing until based_on
  # has a score. The equipment changes outside of the page (the inventory of the game room): no JavaScript twin
  class WornArmorClass < Base
    KEY = "worn_armor_class".freeze
    REQUIRED_PARAMETERS = %w[based_on].freeze
    LIVE = false

    def value(field, reader)
      modifier = reader.modifier(field["based_on"])
      return unless modifier

      armor_class = body_armor_class(field, reader, modifier) + shield_bonus(reader)
      (armor_class + reader.typed_number(field["bonus_from"])).to_s
    end

    private

    def body_armor_class(field, reader, modifier)
      armor = reader.equipped_items.find { |properties| properties[Equippable::ARMOR_FIELD].present? }
      return unarmored(field, reader, modifier) unless armor

      cap = armor[Equippable::DEXTERITY_CAP_FIELD]
      armor[Equippable::ARMOR_FIELD].to_i + (cap ? [modifier, cap.to_i].min : modifier) +
        reader.fighting_style_effects["armored_armor_class_bonus"].to_i
    end

    # The unarmored defense of the class, unless it counts only without a shield and one is equipped (the monk)
    def unarmored(field, reader, modifier)
      class_effects = reader.class_effects(field["class_from"])
      return 10 + modifier if class_effects["unarmored_defense_without_shield"] && shield_bonus(reader).positive?

      10 + modifier + reader.modifier(class_effects["unarmored_defense"]).to_i
    end

    def shield_bonus(reader)
      reader.equipped_items.sum { |properties| properties[Equippable::SHIELD_FIELD].to_i }
    end
  end
end
