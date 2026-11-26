module DiceRolls
  # A roll of initiative asked from the panel « Dés » of the game room, by the rule the template declares
  # (character_fields.dice_rolls.initiative: a die, plus a field of the sheet of a character, another of the sheet of
  # an NPC): rolled by the server (Roller), then written in the feed of the table (ChatMessage) under the name of the
  # character. A player rolls for their own character; the game master for the NPCs and enemies of the table only
  # (decision of 26 November: each player rolls their own), and may roll hidden. The mode of the panel (advantage)
  # applies on the die of the initiative. Anything else raises Roller::InvalidRoll. The roll keeps the id of the
  # character: the strip of the fighters reads it (CombatStrip), and the game master's strip gets the new order at
  # once (CombatStrip#broadcast_initiative_ranks)
  class InitiativeRecorder
    include Modes

    # asked: what the panel sends (character_id, mode_key, hidden)
    def initialize(participation, asked, random: Random.new)
      @participation = participation
      @game_table = participation.game_table
      @rule = @game_table.dice_rolls["initiative"]
      @asked = asked
      @random = random
    end

    def call
      raise Roller::InvalidRoll, "the template has no initiative" unless @rule

      line = record(rolling_character)
      CombatStrip.broadcast_initiative_ranks(@game_table)
      line
    end

    private

    def record(character)
      mode = declared_mode(@game_table, @asked[:mode_key])
      result = Roller.new(count: 1, sides: @rule["sides"], bonus: modifier_of(character), mode:, random: @random).call
      ChatMessage.record_event(@game_table, :initiative_rolled, game_master_only: hidden?,
                                                                label: @rule["label"], character: character.name,
                                                                character_id: character.id,
                                                                notation: notation(result, mode),
                                                                dice: result.dice, total: result.total)
    end

    def rolling_character
      character = @participation.game_master? ? table_character : @participation.character
      raise Roller::InvalidRoll, "no character to roll for" if character.nil? || character.draft?

      character
    end

    def table_character
      @game_table.npcs.find_by(id: @asked[:character_id])
    end

    # The value of the field the rule names, worked out like the sheet shows it (a calculated value, the modifier of
    # an ability, a number typed); 0 when the rule names none, or while it has no number yet
    def modifier_of(character)
      key = character.pc? ? @rule["modifier_from"] : @rule["npc_modifier_from"]
      return 0 if key.nil?

      calculated = character.computed_sheet_values
      value = calculated[:values].fetch(key) { calculated[:modifiers].fetch(key) { character.sheet.to_h[key] } }
      value.is_a?(Integer) ? value : 0
    end

    def hidden?
      @asked[:hidden] && @participation.game_master?
    end
  end
end
