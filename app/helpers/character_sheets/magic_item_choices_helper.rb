# The magic items and the gold more of a character created above level 1, at the step of the equipment
# (CharacterHigherLevelEquipment): what its level gives, and one list per place
module CharacterSheets
  module MagicItemChoicesHelper
    SCOPE = "game_tables.character_steps.magic_item_choices".freeze
    # The pick of a line, as the picks of the equipment (EquipmentChoicesHelper::PICK_CLASSES), wider: the names of
    # the magic items are longer (« Amulette de santé physique »)
    PICK_CLASSES = EquipmentChoicesHelper::PICK_CLASSES.sub("max-w-48", "max-w-72").freeze

    # « + 500 pièces d'or et 1d10 × 25 pièces d'or, lancées quand vous terminez votre personnage. », nil without gold
    def higher_level_gold_text(tier)
      fixed = tier["gold"].to_i
      roll = tier["gold_roll"]
      return if fixed.zero? && roll.nil?

      rolled = roll && t("#{SCOPE}.gold_roll", dice: roll["dice"], sides: roll["sides"],
                                               multiplier: number_with_delimiter(roll["multiplier"]))
      return t("#{SCOPE}.gold_fixed", amount: number_with_delimiter(fixed)) unless rolled
      return t("#{SCOPE}.gold_rolled_only", roll: rolled) if fixed.zero?

      t("#{SCOPE}.gold", amount: number_with_delimiter(fixed), roll: rolled)
    end

    # The rarity of the place, numbered when its tier gives several of it (« Peu commune 2 »)
    def magic_item_place_label(character, place, places)
      rarity = character.magic_item_rarity_label(place.rarity)
      several = places.count { |other| other.rarity == place.rarity } > 1
      several ? t("#{SCOPE}.numbered_place", rarity: rarity, number: place.number) : rarity
    end

    # The names of the magic items picked, for the summary
    def starting_magic_item_names(character)
      character.magic_item_places.filter_map do |place|
        value = character.starting_magic_items.to_h[place.key]
        character.magic_item_choices(place.rarity).find { |choice| choice.value == value }&.name
      end
    end

    def magic_item_options(character, place)
      choices = character.magic_item_choices(place.rarity).map { |choice| [choice.name, choice.value] }
      options_for_select(choices, character.starting_magic_items.to_h[place.key])
    end
  end
end
