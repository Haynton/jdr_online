module ChoiceEffects
  # The spells always prepared from a level of the character, by key of the catalog of spells (the domain spells of
  # the Life domain: { "3" => ["aid", "bless"], "5" => [...] }). They do not count among the spells to choose: read by
  # CharacterSheets::SpellChoices, copied into the character beside those chosen
  class AlwaysPreparedSpells < Base
    include Levels

    KEY = "always_prepared_spells".freeze

    def value_errors(value, **)
      return [] if by_level?(value) && value.values.flatten.all?(String)

      [[:invalid_level_entries, { effect: KEY }]]
    end

    # The keys of the spells prepared at that level
    def spell_keys(value, level)
      up_to_level(value, level)
    end
  end
end
