# The spells the options picked always prepare from a level of the character (always_prepared_spells: the domain
# spells of the Life domain), beside the groups of spells to choose (CharacterSheets::SpellChoices): they count in no
# group, and the character keeps a copy of each, marked so (CharacterSpellsValidator lets them through). A spell the
# table no longer offers is left out
module CharacterSheets
  class AlwaysPreparedSpells
    # options: [option, value of the effect] for each option picked with the effect ("Domaine de la Vie"); spells: the
    # spells of the catalog of the table
    def initialize(options:, level:, spells:)
      @options = options
      @level = level
      @spells = spells
    end

    def keys
      @keys ||= @options.flat_map { |_option, value| effect.spell_keys(value, @level) }.uniq
    end

    # The catalog entries, by level then by name
    def entries
      @entries ||= keys.empty? ? [] : @spells.where(key: keys).by_level_and_name.to_a
    end

    def any?
      entries.any?
    end

    # The options that give them, as the page names where they come from
    def sources
      @options.map(&:first)
    end

    def copies
      entries.map { |entry| CharacterSheets::SpellChoices.copy_of_entry(entry).merge("always_prepared" => true) }
    end

    private

    def effect
      ChoiceEffects.find(ChoiceEffects::AlwaysPreparedSpells::KEY)
    end
  end
end
