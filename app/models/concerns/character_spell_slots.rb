# The spell slots a player's character spends in the game room (decision of 26 November: saved, by its player or the
# game master, a line in the chat of the game master only), by level of spell in spell_slots_used. A long rest gives
# them all back; a short rest those of a class whose slots come back then (CharacterSheets::SpellSlots#short_rest: the
# pact slots, declared by the template)
module CharacterSpellSlots
  extend ActiveSupport::Concern

  def spell_slots
    CharacterSheets::SpellSlots.new(self).call if pc?
  end

  # amount spent when positive, given back when negative. The error, nil once changed (not saved here)
  def change_spell_slot(spell_level, amount)
    slots = spell_slots
    return :no_slot unless slots&.total(spell_level)&.positive?

    used = slots.used_at(spell_level) + amount
    return :not_enough if used > slots.total(spell_level)
    return :nothing_spent if used.negative?

    self.spell_slots_used = spell_slots_used.to_h.merge(spell_level.to_s => used)
    nil
  end

  def give_back_spell_slots(short_rest: false)
    return if short_rest && !spell_slots&.short_rest

    self.spell_slots_used = {}
  end
end
