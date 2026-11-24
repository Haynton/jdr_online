# The spell slots of a character, as the template declares them (character_fields.spell_slots, decision: shown only,
# their use in the game comes with the game sheet): the table count_from of the class (heroic fantasy: slots), its
# list at the level of the character, a number per level of spell from level 1. The label and the help are the
# template's, or the class's own when it gives them (label_from, help_from: the pact slots of heroic fantasy, all of
# one level, regained after a short rest): no rule of a game is written here
module CharacterSheets
  class CharacterSheets::SpellSlots
    # The label and help to show, and [level of spell, count] for each level with slots
    Slots = Data.define(:label, :help, :counts)

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
                help: class_value("help_from") || @declared["help"], counts: counts)
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

    def class_value(setting)
      spell_choices.spellcasting[@declared[setting]].presence if @declared[setting]
    end
  end
end
