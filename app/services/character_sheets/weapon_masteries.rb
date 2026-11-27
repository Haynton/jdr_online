# What a character may pick of the weapon masteries and the fighting style its class gives at its level (decision of
# 26 November, SRD 5.2.1), read in the effects of the options it picked (ChoiceEffects::WeaponMastery,
# ::FightingStyle) and in the catalog of its table: how many kinds of weapons, which ones (those its class is trained
# in, by category or by kind; melee only for the barbarian), each with its mastery property and the rule of it (the
# field mastery of the item sheet); and the styles it may pick (character_fields.fighting_styles)
module CharacterSheets
  class WeaponMasteries
    # A kind of weapon to pick: its key, its name, its mastery property and the rule of that property
    Kind = Data.define(:key, :label, :mastery, :rule)
    Style = Data.define(:key, :label, :help, :effects)

    def initialize(character)
      @character = character
      @game_table = character.game_table
      @level = character.spell_choices.level
    end

    def allowed_count
      Array(class_effects.dig("weapon_mastery", "counts"))[@level - 1].to_i
    end

    def offered_kinds
      @offered_kinds ||= begin
        kinds = weapons_by_kind.filter_map { |kind, weapon| kind_entry(kind, weapon) if offered_weapon?(kind, weapon) }
        kinds.sort_by { |kind| I18n.transliterate(kind.label).downcase }
      end
    end

    def offered_styles
      declared = class_effects["fighting_style"]
      return [] unless declared && @level >= declared["level"].to_i

      fighting_styles.select { |style| declared["options"].include?(style.key) }
    end

    # The styles of the template, by key (the effects of the one picked: CharacterWeaponMasteries)
    def fighting_styles
      Array(@game_table.fighting_styles).map do |style|
        Style.new(key: style["key"], label: style["label"], help: style["help"], effects: style["effects"].to_h)
      end
    end

    def offered?
      allowed_count.positive? || offered_styles.any?
    end

    private

    def class_effects
      @class_effects ||= SheetReader.new(fields: @character.sheet_fields, sheet: @character.sheet, level_thresholds: [],
                                         modifiers: {}).class_effects(class_list_key)
    end

    # The list whose options give the training (the class): the one the weapon attacks read
    def class_list_key
      @game_table.weapon_attacks.to_h["training_from"]
    end

    def weapons_by_kind
      Catalogs::TableCatalog.new(@game_table).entries("item").to_a.select { |item| item.properties["weapon_kind"] }
                            .index_by { |item| item.properties["weapon_kind"] }
    end

    def offered_weapon?(kind, weapon)
      training = Array(class_effects["training"])
      return false if class_effects.dig("weapon_mastery", "melee_only") && weapon.properties["ranged"]

      [weapon.properties["training"], kind].intersect?(training)
    end

    def kind_entry(kind, weapon)
      field = item_field("weapon_kind")
      mastery_field = item_field("mastery")
      mastery = weapon.properties["mastery"]
      Kind.new(key: kind, label: FieldTypes.of(field).summary_text(kind, field) || weapon.name,
               mastery: mastery && FieldTypes.of(mastery_field).summary_text(mastery, mastery_field),
               rule: mastery_field&.dig("descriptions", mastery))
    end

    def item_field(key)
      @item_fields ||= CatalogEntry.declared_fields(@game_table, "item_fields")
      @item_fields.find { |field| field["key"] == key }
    end
  end
end
