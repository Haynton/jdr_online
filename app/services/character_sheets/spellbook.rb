# The spellbook of a character whose class has one (decision of 27 November, SRD 5.2.1: the wizard): the level 1+
# spells it knows, start at creation and per_level more at each level gained (the effect spellcasting of its class:
# spellbook), among the spells of the group prepares_from (the spells it may prepare: its levels with spell slots).
# The spells of that group are prepared among them. A copy of each spell is kept (characters.spellbook), as the spells
# prepared. No rule of a game is written here: the class declares it
module CharacterSheets
  class Spellbook
    def initialize(character)
      @character = character
      @spell_choices = character.spell_choices
    end

    def settings
      @spell_choices.spellcasting["spellbook"]
    end

    def any?
      settings.present? && group.present?
    end

    def label
      settings["label"]
    end

    def help
      settings["help"]
    end

    # How many spells it holds at that level: start, then per_level more for each level after the first
    def size(level = @spell_choices.level)
      settings["start"].to_i + (settings["per_level"].to_i * (level - 1))
    end

    # The group whose spells are prepared from the book (its spells are those the book may hold)
    def group
      @group ||= settings && @spell_choices.groups.find { |candidate| candidate.key == settings["prepares_from"] }
    end

    def keys
      Array(@character.spellbook).pluck("key")
    end

    def include?(spell_key)
      keys.include?(spell_key)
    end

    # A copy of each spell written, the keys not offered kept bare (refused by the validator)
    def copies_of(spell_keys)
      spell_keys.to_a.compact_blank.uniq.map { |key| @spell_choices.copy_of(key) || { "key" => key } }
    end

    # The spells it may copy into its book (a spell found in the game): those of its group not written yet, nor known
    # otherwise
    def copyable
      known = @character.feat_spells.known_elsewhere.keys
      group.spells.reject { |spell| include?(spell.key) || known.include?(spell.key) }
    end

    # What copying a spell costs: [field of the coin, amount], nil when the class declares no cost
    def copy_cost(spell)
      cost = settings["copy_cost"]
      field = cost && @character.currency_field(cost["currency"])
      field && [field, cost["per_level"].to_i * spell.properties["level"].to_i]
    end

    # The errors of the book: a spell its group does not offer, more spells than its size, a spell prepared that it does
    # not hold
    def errors
      found = []
      found << [:spellbook_not_offered, {}] if (keys - group.keys).any?
      found << [:spellbook_too_full, { label: label, count: size }] if keys.size > size
      found << [:prepared_outside_spellbook, { label: label }] if prepared_outside.any?
      found
    end

    private

    def prepared_outside
      @character.spells.to_a.select { |spell| group.keys.include?(spell["key"]) && !include?(spell["key"]) }
    end
  end
end
