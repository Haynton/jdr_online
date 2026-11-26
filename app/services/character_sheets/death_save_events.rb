# The lines the death saving throws of a character write in the feed of its table (ChatMessage), for everyone
# (decision of 26 November): a roll and what it did, a hit taken at 0 hit points, then the character stable or dead.
# Made before a change (it notes how things stood), recorded once the change is saved
module CharacterSheets
  class DeathSaveEvents
    OUTCOME_EVENTS = {
      revived: :death_save_revived, critical_failure: :death_save_critical_failure, success: :death_save_success,
      failure: :death_save_failure
    }.freeze

    def initialize(character)
      @character = character
      @failures_before = character.death_saves_settings ? character.death_save_failures : 0
      @dead_before = character.dead?
      @stable_before = character.stable?
    end

    # roll and outcome: those of a roll (CharacterDeathSaves#take_death_save), nil for a hit or a heal
    def record(roll: nil, outcome: nil)
      return unless @character.death_saves_settings

      write(OUTCOME_EVENTS.fetch(outcome), roll: roll) if outcome
      state_event = state_event(outcome)
      write(state_event) if state_event
    end

    private

    def state_event(outcome)
      return :death_save_dead if @character.dead? && !@dead_before
      return :death_save_stable if @character.stable? && !@stable_before
      return :death_save_hit if outcome.nil? && @character.death_save_failures > @failures_before

      nil
    end

    def write(event_key, **values)
      counts = { successes: @character.death_save_successes, failures: @character.death_save_failures,
                 needed: @character.death_saves_needed }
      ChatMessage.record_event(@character.game_table, event_key, character: @character.name, **counts, **values)
    end
  end
end
