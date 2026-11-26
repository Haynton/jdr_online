# A player changes the fighting style and the weapon masteries of their character during the game, from the panel
# « Ma fiche » of the game room (decision of 26 November: the rules allow it after a long rest, the game master
# judges), within what their class gives at their level (CharacterWeaponMasteriesValidator). The choices are those of
# the step of the skills (game_tables/character_steps/_weapon_mastery_choices), in the window of the room; the change is
# written in the chat. Only a player accepted at the table, with a complete character whose class gives either; anyone
# else gets a 404
module GameTables
  class WeaponMasteryChoicesController < ApplicationController
    include VariesOnTurboFrame

    before_action :set_own_character

    def edit
    end

    def update
      before = chosen_labels
      @character.choose_weapon_masteries(choice_params[:fighting_style], choice_params[:weapon_mastery_keys])
      return render(:edit, status: :unprocessable_content) unless @character.save

      record_change(before)
      render turbo_stream: turbo_stream.refresh(request_id: nil)
    end

    private

    def set_own_character
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @game_table = participation.game_table
      @character = participation.character
      raise ActiveRecord::RecordNotFound unless @character&.complete? && @character.weapon_mastery_choices.offered?
    end

    def choice_params
      params.fetch(:character, {}).permit(:fighting_style, weapon_mastery_keys: [])
    end

    # The style and the kinds picked, by their names in the template
    def chosen_labels
      choices = @character.weapon_mastery_choices
      style = choices.fighting_styles.find { |candidate| candidate.key == @character.fighting_style }&.label
      kinds = choices.offered_kinds.select { |kind| @character.weapon_masteries.to_a.include?(kind.key) }.map(&:label)
      [style, *kinds].compact
    end

    # Written without a word of any language (« + Défense, Arcs longs · − Archerie »), as a change of spells
    def record_change(before)
      after = chosen_labels
      added = after - before
      removed = before - after
      return if added.empty? && removed.empty?

      changes = [("+ #{added.join(', ')}" if added.any?), ("− #{removed.join(', ')}" if removed.any?)]
      ChatMessage.record_event(@game_table, :weapon_masteries_changed, character: @character.name,
                                                                       changes: changes.compact.join(" · "))
    end
  end
end
