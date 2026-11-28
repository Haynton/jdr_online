# A player changes the options of the groups of choices of their character during the game (decision of 27 November:
# the invocations and the metamagic at a level gained, the prey and tactics of the hunter after a rest, the land of the
# circle after a long rest; the game master judges), from the panel « Ma fiche » of the game room, within what their
# class gives at their level (CharacterClassChoicesValidator). The choices are those of the step of the skills
# (game_tables/character_steps/_class_choices), in the window of the room; the change is written in the chat. Only a
# player accepted at the table, with a complete character whose class gives some; anyone else gets a 404
module GameTables
  class ClassChoicesController < ApplicationController
    include VariesOnTurboFrame

    before_action :set_own_character

    def edit
    end

    def update
      before = chosen_labels
      @character.choose_class_choices(params.fetch(:character, {}).permit(class_choices: {})[:class_choices])
      return render(:edit, status: :unprocessable_content) unless @character.save

      record_change(before)
      render turbo_stream: turbo_stream.refresh(request_id: nil)
    end

    private

    def set_own_character
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @game_table = participation.game_table
      @character = participation.character
      raise ActiveRecord::RecordNotFound unless @character&.complete? && @character.class_choice_groups.offered?
    end

    # The options picked, by their names in the template
    def chosen_labels
      @character.class_choice_groups.groups.flat_map { |group| group.picked_options.map(&:label) }
    end

    # Written without a word of any language (« + Sort subtil · − Sort jumeau »), as a change of spells
    def record_change(before)
      after = chosen_labels
      added = after - before
      removed = before - after
      return if added.empty? && removed.empty?

      changes = [("+ #{added.join(', ')}" if added.any?), ("− #{removed.join(', ')}" if removed.any?)]
      ChatMessage.record_event(@game_table, :class_choices_changed, character: @character.name,
                                                                    changes: changes.compact.join(" · "))
    end
  end
end
