# A player makes their character before joining the game (decision): one page with its name and the fields of the
# template copied into the table. Only a player of the table who has no character yet: the game master, anyone else,
# or an invitation not answered yet get a 404. The full creation in steps comes with card #59 (P4)
module GameTables
  class CharactersController < ApplicationController
    before_action :set_participation
    before_action :redirect_if_character_made

    def new
      @character = @participation.build_character(game_table: @game_table, kind: :pc)
      @computed_sheet_values = @character.computed_sheet_values
    end

    # For screen readers only: on screen, the page of the table follows
    def create
      @character = build_character
      return render_form_again unless @character.save

      redirect_to game_table_path(@game_table),
                  flash: { screen_reader_notice: t(".created", name: @character.name) }
    end

    private

    def set_participation
      @participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @game_table = @participation.game_table
    end

    def redirect_if_character_made
      redirect_to game_table_path(@game_table) unless @participation.needs_character?
    end

    def build_character
      sheet = CharacterSheetBuilder.new(fields: @game_table.character_creation_fields,
                                        submitted_values: character_params[:sheet]).call
      @participation.build_character(game_table: @game_table, kind: :pc, name: character_params[:name], sheet: sheet)
    end

    # The form again with what was typed, its errors and the values worked out from it
    def render_form_again
      @computed_sheet_values = @character.computed_sheet_values
      render :new, status: :unprocessable_content
    end

    def character_params
      params.expect(character: [:name, { sheet: {} }])
    end
  end
end
