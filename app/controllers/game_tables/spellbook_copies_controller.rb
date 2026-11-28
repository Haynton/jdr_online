# A wizard copies into its spellbook a spell found during the game (decision of 27 November, SRD 5.2.1: a spell scroll,
# for a cost in gold per level of the spell, declared by its class: copy_cost), from the window « Changer mes sorts »
# of the game room: the cost is taken from its purse (refused when it has not enough), the spell written in the book,
# and the copy written in the chat of the table (the game master judges whether the spell was found). Only a player
# accepted at the table, with a complete character whose class has a spellbook; anyone else gets a 404
module GameTables
  class SpellbookCopiesController < ApplicationController
    include VariesOnTurboFrame

    def create
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @game_table = participation.game_table
      @character = participation.character
      book = @character&.complete? && @character.spellbook_of_class
      raise ActiveRecord::RecordNotFound unless book&.any?

      spell = book.copyable.find { |candidate| candidate.key == params[:spell_key] }
      raise ActiveRecord::RecordNotFound unless spell

      copy(book, spell)
    end

    private

    def copy(book, spell)
      field, amount = book.copy_cost(spell)
      return refuse if field && @character.change_money(field, -amount)

      @character.spellbook = @character.spellbook.to_a + [book.found_copy_of(spell.key)]
      @character.save!(validate: false)
      record(spell, field, amount)
      render turbo_stream: turbo_stream.refresh(request_id: nil)
    end

    def refuse
      @copy_error = t(".not_enough")
      render "game_tables/spell_choices/edit", status: :unprocessable_content
    end

    def record(spell, field, amount)
      ChatMessage.record_event(@game_table, :spell_copied, character: @character.name, spell: spell.name,
                                                           count: amount.to_i, coin: field ? coin_of(field) : "")
    end

    def coin_of(field)
      field["abbreviation"] || field["label"]
    end
  end
end
