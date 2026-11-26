# A spell slot of a player's character spent or given back in the game room (decision of 26 November), by its player
# or the game master (SharesCharacterVitals: a 404 for anyone else), never more than it has nor below nothing spent. A
# slot spent is written in the chat of the game master only (a line game_master_only); given back is a correction, not
# written. The new slots go to the whole table at once
module GameTables
  class CharacterSpellSlotsController < ApplicationController
    include SharesCharacterVitals

    before_action { find_character_of_table(params[:character_vital_id]) }

    def update
      spell_level = params[:level].to_i
      spent = params[:resource_change] == "spend"
      return head(:unprocessable_content) if @character.change_spell_slot(spell_level, spent ? 1 : -1)

      save_and_share { record_slot_spent(spell_level) if spent }
    end

    private

    def record_slot_spent(spell_level)
      slots = @character.spell_slots
      total = slots.total(spell_level)
      ChatMessage.record_event(@game_table, :spell_slot_spent, game_master_only: true, character: @character.name,
                                                               level: spell_level, total: total,
                                                               left: total - slots.used_at(spell_level))
    end
  end
end
