# The spell slots of a character, as the template declares them (character_fields.spell_slots; spent in the game room
# since 26 November, CharacterSpellSlots): the table count_from of the class (heroic fantasy: slots), its
# list at the level of the character, a number per level of spell from level 1. The label and the help are the
# template's, or the class's own when it gives them (label_from, help_from: the pact slots of heroic fantasy, all of
# one level, regained after a short rest): no rule of a game is written here
module CharacterSheets
  class CharacterSheets::SpellSlots
    # The label and help to show, [level of spell, count] for each level with slots, what is spent by level of spell
    # ({ 1 => 2 }), and whether they come back after a short rest (recovery_from: the pact slots)
    Slots = Data.define(:label, :help, :counts, :used, :short_rest) do
      def total(spell_level)
        counts.to_h.fetch(spell_level, 0)
      end

      def used_at(spell_level)
        used.fetch(spell_level, 0)
      end
    end

    def initialize(character)
      @character = character
      @declared = character.game_table.spell_slots
    end

    # nil for a template without slots, or a class with none at this level
    def call
      return if @declared.blank?

      counts = counts_at_level
      return if counts.empty?

      Slots.new(label: class_value("label_from") || @declared["label"],
                help: class_value("help_from") || @declared["help"], counts: counts, used: used_by_level(counts),
                short_rest: class_value("recovery_from") == "short_rest")
    end

    private

    def spell_choices
      @spell_choices ||= @character.spell_choices
    end

    def counts_at_level
      table = spell_choices.spellcasting[@declared["count_from"]]
      return [] unless table.is_a?(Array)

      table[spell_choices.level - 1].to_a.each.with_index(1).filter_map do |count, spell_level|
        [spell_level, count] if count.to_i.positive?
      end
    end

    # What is spent, never more than the slots of that level (a level lost, a class changed)
    def used_by_level(counts)
      spent = @character.spell_slots_used.to_h
      counts.to_h { |spell_level, count| [spell_level, spent[spell_level.to_s].to_i.clamp(0, count)] }
    end

    def class_value(setting)
      spell_choices.spellcasting[@declared[setting]].presence if @declared[setting]
    end
  end
end
