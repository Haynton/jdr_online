# The spells a character may choose at the Spells step, read from the option picked with a spellcasting effect (the
# class) and the level of the character: its cantrips among the spells of level 0 of that class, its prepared spells
# among those of level 1 up to the highest spell level it can cast (spellcasting: cantrips, prepared, max_spell_level,
# by level from 1 to 20). The spells come from the catalog of the template of the table (catalog_entries).
# Known limit: the spellbook of the wizard (6 spells, some of them prepared) comes later; here every class prepares
# its spells from the list of its class
module CharacterSheets
  class CharacterSheets::SpellChoices
    # cantrips or prepared, how many may be chosen, and the spells offered (catalog entries, by level then by name)
    Group = Data.define(:kind, :allowed_count, :spells) do
      def keys
        spells.map(&:key)
      end
    end

    def initialize(character)
      @character = character
      @game_table = character.game_table
    end

    # When the prepared spells can be changed during the game (spellcasting: prepared_changes): the whole list after a
    # long rest (cleric, druid, wizard), one after a long rest (paladin, ranger), one per level gained (bard, sorcerer,
    # warlock). The cantrips: one per level gained, for every class (rules of 2024)
    PREPARED_CHANGES = %w[long_rest long_rest_one level_up_one].freeze

    def prepared_changes
      spellcasting["prepared_changes"]
    end

    # The groups to choose from, those with nothing to choose left out: [] for a class without spells
    def groups
      @groups ||= [
        Group.new(kind: :cantrips, allowed_count: count_at_level("cantrips"), spells: catalog_spells.of_level(0).to_a),
        Group.new(kind: :prepared, allowed_count: count_at_level("prepared"),
                  spells: catalog_spells.of_level(1..max_spell_level).to_a)
      ].select { |group| group.allowed_count.positive? && !group.spells.empty? }
    end

    def group_of(spell_key)
      groups.find { |group| group.keys.include?(spell_key) }
    end

    # The copies of the spells chosen that are still offered, at most as many per group as allowed: the spells kept
    # when the class changes (a spell of the class before goes)
    def keep_offered(chosen_spells)
      chosen_spells.select { |spell| group_of(spell["key"]) }
                   .group_by { |spell| group_of(spell["key"]) }
                   .flat_map { |group, spells_of_group| spells_of_group.first(group.allowed_count) }
    end

    # What a character keeps of a spell: a copy, which the catalog changing never changes (decision)
    def copy_of(spell_key)
      entry = groups.flat_map(&:spells).find { |spell| spell.key == spell_key }
      entry && { "key" => entry.key, "name" => entry.name, "level" => entry.level,
                 "description" => entry.description, "properties" => entry.properties }
    end

    private

    def catalog_spells
      sheet_template = @game_table.sheet_template
      return CatalogEntry.none unless sheet_template && class_option

      sheet_template.catalog_entries.spells.for_class(class_option).by_level_and_name
    end

    def count_at_level(name)
      spellcasting.dig(name, level - 1).to_i
    end

    def max_spell_level
      spellcasting.dig("max_spell_level", level - 1).to_i
    end

    # The level of the character (the field filled by the table, starting_level), between 1 and 20
    def level
      level_field = @game_table.character_sheet_fields.find { |field| field["from_table"] == "starting_level" }
      value = level_field && @character.sheet[level_field["key"]]
      (value || @game_table.starting_level).to_i.clamp(1, 20)
    end

    def spellcasting
      picked_spellcasting&.last || {}
    end

    # The option picked with a spellcasting effect (the class: "Magicien")
    def class_option
      picked_spellcasting&.first
    end

    def picked_spellcasting
      @picked_spellcasting ||= @game_table.character_sheet_fields.filter_map do |field|
        option = @character.sheet[field["key"]]
        spellcasting = field.dig("effects", option.to_s, "spellcasting")
        [option, spellcasting] if spellcasting
      end.first
    end
  end
end
