# A player changes the spells of their character during the game, from the panel « Sorts » of the game room
# (decision of 26 November: whenever they like, within the numbers of their class and their level, which
# CharacterSpellsValidator checks; each change is written in the chat, so that the game master sees it). The list is
# the one of the Spells step of the creation (game_tables/character_steps/_spell_choices), in the window of the room.
# Only a player accepted at the table, with a complete character who has spells to choose; anyone else gets a 404
module GameTables
  class SpellChoicesController < ApplicationController
    include VariesOnTurboFrame

    before_action :set_own_character

    def edit
    end

    # Saved: the room is refreshed (its panel « Sorts », the window closed), the change written in the chat. Refused
    # (too many spells in a group), the list comes back with its errors
    def update
      spells_before = chosen_spell_names
      @character.choose_spells(spell_keys_params)
      return render(:edit, status: :unprocessable_content) unless @character.save

      record_change(spells_before)
      render turbo_stream: turbo_stream.refresh(request_id: nil)
    end

    private

    def set_own_character
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @game_table = participation.game_table
      @character = participation.character
      raise ActiveRecord::RecordNotFound unless @character&.complete? && @character.spell_choices.groups.any?
    end

    def spell_keys_params
      params.fetch(:character, {}).permit(spell_keys: [])[:spell_keys]
    end

    # The spells the player chose (those always prepared never change here), by key
    def chosen_spell_names
      @character.spells.to_a.reject { |spell| spell["always_prepared"] }.to_h { |spell| [spell["key"], spell["name"]] }
    end

    def record_change(spells_before)
      spells_after = chosen_spell_names
      added = spells_after.values_at(*(spells_after.keys - spells_before.keys))
      removed = spells_before.values_at(*(spells_before.keys - spells_after.keys))
      return if added.empty? && removed.empty?

      ChatMessage.record_event(@game_table, :spells_changed, character: @character.name,
                                                             changes: spell_changes_text(added, removed))
    end

    # Written without a word of any language (« + Aide, Bénédiction · − Soins »): the sentence around it is read in
    # the language of each reader, the names of the spells are those of the template
    def spell_changes_text(added, removed)
      [("+ #{added.join(', ')}" if added.any?), ("− #{removed.join(', ')}" if removed.any?)].compact.join(" · ")
    end
  end
end
