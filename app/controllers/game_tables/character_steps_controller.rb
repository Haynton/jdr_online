# The steps of the creation of a character (CharacterCreationSteps), saved as a draft after each one (decision): the
# player can leave and come back where they were. A step opens once reached; the summary makes the character complete.
# Only a player of the table whose character is not complete yet: the game master, anyone else, or an invitation not
# answered yet get a 404
module GameTables
  class CharacterStepsController < ApplicationController
    before_action :set_participation
    before_action :redirect_if_character_complete
    before_action :set_character
    before_action :set_step

    def show
      @computed_sheet_values = @character.computed_sheet_values
    end

    def update
      return complete_character if @step.summary?

      @character.fill_step(@step, sheet_values: step_params[:sheet], name: step_params[:name])
      next_step = @character.creation_steps.after(@step)
      @character.reach_creation_step(next_step.key)
      return render_step_again unless @character.save

      redirect_to game_table_character_step_path(@game_table, next_step.key)
    end

    private

    def set_participation
      @participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @game_table = @participation.game_table
    end

    def redirect_if_character_complete
      redirect_to game_table_path(@game_table) unless @participation.needs_character?
    end

    # The draft, or a new one starting with what the table gives (its level)
    def set_character
      @character = @participation.character ||
                   @participation.build_character(game_table: @game_table, kind: :pc, status: :draft,
                                                  sheet: @game_table.character_values_from_table)
    end

    # A step not reached yet (or unknown, or gone: no spells for this class) is not found
    def set_step
      @step = @character.creation_steps.find(params[:step])
      raise ActiveRecord::RecordNotFound unless @step && @character.creation_step_reached?(@step)
    end

    # For screen readers only: on screen, the page of the table follows
    def complete_character
      @character.complete_creation
      return render_step_again unless @character.save

      redirect_to game_table_path(@game_table),
                  flash: { screen_reader_notice: t(".created", name: @character.name) }
    end

    def render_step_again
      @computed_sheet_values = @character.computed_sheet_values
      render :show, status: :unprocessable_content
    end

    # Nothing sent on the summary, whose button only confirms
    def step_params
      params.fetch(:character, {}).permit(:name, sheet: {})
    end
  end
end
