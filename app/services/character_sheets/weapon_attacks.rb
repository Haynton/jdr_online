# The attacks of the weapons a player's character holds (decision of 26 November), in the form of the attacks of a
# creature ({ name, to_hit, damage }: FieldTypes::Attacks), so that the room shows them the same way. The template
# says how they are worked out (character_fields.weapon_attacks, checked by SheetTemplates::WeaponAttacksCheck): a
# melee weapon uses melee_ability (Strength), a ranged one ranged_ability (Dexterity), a finesse one the better of the
# two; the bonus to hit adds the proficiency bonus when the class (training_from) has the training the weapon needs;
# the damage is its dice plus the same modifier. A versatile weapon gives a second line, with two hands, while no
# shield is equipped (decision: the player takes the line that fits how they hold it)
module CharacterSheets
  class WeaponAttacks
    def initialize(character)
      @character = character
      @settings = character.game_table.weapon_attacks
    end

    def call
      return [] unless @settings

      items = @character.equipped_items
      holds_shield = items.any?(&:shield?)
      items.select(&:weapon?).flat_map { |weapon| lines_of(weapon, holds_shield) }
    end

    private

    def lines_of(weapon, holds_shield)
      modifier = modifier_for(weapon.properties)
      to_hit = modifier + proficiency_for(weapon.properties)
      lines = [attack_line(weapon.name, to_hit, weapon.properties["damage_dice"], modifier, weapon.properties)]
      two_handed_dice = weapon.properties["versatile_dice"]
      return lines if two_handed_dice.blank? || holds_shield

      lines << attack_line(two_handed_name(weapon.name), to_hit, two_handed_dice, modifier, weapon.properties)
    end

    def attack_line(name, to_hit, dice, modifier, properties)
      damage = ["#{dice}#{signed(modifier) unless modifier.zero?}", properties["damage_type"]].compact_blank.join(" ")
      { "name" => name, "to_hit" => to_hit, "damage" => damage }
    end

    def two_handed_name(name)
      label = @settings["two_handed_label"]
      label.present? ? "#{name}, #{label}" : name
    end

    def modifier_for(properties)
      melee, ranged = modifiers.values_at(@settings["melee_ability"], @settings["ranged_ability"]).map(&:to_i)
      return [melee, ranged].max if properties["finesse"]

      properties["ranged"] ? ranged : melee
    end

    def proficiency_for(properties)
      return 0 unless trained_with?(properties["training"])

      computed[:values][@settings["proficiency"]].to_i
    end

    def trained_with?(training)
      return false if training.blank? || @settings["training_from"].blank?

      reader = SheetReader.new(fields: @character.sheet_fields, sheet: @character.sheet, level_thresholds: [],
                               modifiers: {})
      Array(reader.class_effects(@settings["training_from"])["training"]).include?(training)
    end

    def modifiers
      computed[:modifiers]
    end

    def computed
      @computed ||= @character.computed_sheet_values
    end

    def signed(number)
      number.negative? ? number.to_s : "+#{number}"
    end
  end
end
