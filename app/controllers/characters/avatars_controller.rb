module Characters
  # The picture of a character (HasAvatar), only the player's own (404 for anyone else's). Two addresses: while it is
  # made, by its table (/game_tables/:id/character/avatar), the draft saved first if it was not yet (the picture may
  # come before the first "Continue"); once complete, by the character (/characters/:id/avatar, its page "Change").
  # The page sends it without leaving: a Turbo Stream puts back the picker, so nothing typed on the step is lost.
  # Without JavaScript, back to the page
  class AvatarsController < ApplicationController
    before_action :set_own_character

    def update
      changed = @character.change_avatar(params.dig(:character, :avatar))
      @character.send_new_look_to_players if changed
      respond_with_picker(error: (@character.errors.messages_for(:avatar).first unless changed))
    end

    def destroy
      @character.remove_avatar
      @character.send_new_look_to_players
      respond_with_picker(error: nil)
    end

    private

    def set_own_character
      @character = params[:character_id] ? current_user.characters.find(params[:character_id]) : saved_draft
    end

    def picker_layout
      AvatarsHelper::CHARACTER_PICKER_LAYOUTS.find { |layout| layout.to_s == params[:layout] } || :column
    end

    def saved_draft
      participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      participation.character_draft.tap { |draft| draft.save!(validate: false) if draft.new_record? }
    end

    # reload: a picture refused is not kept on the character shown. The picker is put back in the layout it was sent
    # from, and the picture of the band of the creation follows (a page without that band ignores it)
    def respond_with_picker(error:)
      picker = helpers.character_avatar_picker(@character.reload, error: error, layout: picker_layout)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("character-avatar-body", partial: "shared/avatar_picker_body",
                                                          locals: { picker: picker }),
            turbo_stream.replace("creation-hero-avatar", partial: "game_tables/character_steps/hero_avatar",
                                                         locals: { character: @character })
          ], status: error ? :unprocessable_content : :ok
        end
        format.html { redirect_back fallback_location: character_path(@character), alert: error }
      end
    end
  end
end
