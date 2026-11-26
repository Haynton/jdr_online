# The characters of a player on all their tables (« Mes personnages »): the list, the sheet of one of them, and its
# identity and description changed once it is complete (CharacterDescription), also from the window of its sheet in
# the game room. A draft is still made in its steps: its sheet leads back to them. Only the player's own characters:
# 404 for anyone else's
class CharactersController < ApplicationController
  include VariesOnTurboFrame

  before_action :set_own_character, only: %i[show edit update]
  before_action :redirect_draft_to_its_steps, only: %i[show edit update]

  def index
    @characters = current_user.characters.includes(:game_table, avatar_attachment: :blob).order(updated_at: :desc)
  end

  def show
  end

  def edit
  end

  # The sheet shows what was saved: the message is for screen readers only
  def update
    @character.fill_description(name: description_params[:name], sheet_values: description_params[:sheet])
    return render(:edit, status: :unprocessable_content) unless @character.save

    return render(turbo_stream: turbo_stream.refresh(request_id: nil)) if saved_from_game_room?

    redirect_to character_path(@character), flash: { screen_reader_notice: t(".saved") }
  end

  private

  # Saved from the window of the game room: the room is refreshed, so it shows the change (its panels, the strip of
  # the fighters) and the window comes back closed; the player never leaves the game. A refresh with no request id:
  # Turbo would ignore its own
  def saved_from_game_room?
    turbo_frame_request_id == GameRoomHelper::SHEET_FRAME
  end

  def set_own_character
    @character = current_user.characters.find(params[:id])
  end

  def redirect_draft_to_its_steps
    redirect_to new_game_table_character_path(@character.game_table) if @character.draft?
  end

  def description_params
    params.fetch(:character, {}).permit(:name, sheet: {})
  end
end
