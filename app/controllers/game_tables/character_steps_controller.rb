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

    # "Later" in go_to: the step is saved, then "My tables"
    LATER = "later".freeze

    # Continue saves the step and opens the next one. A step of the band, Back or Later save it too (decision: moving
    # between the steps never loses what was typed), then go where they point (go_to), without reaching the next step
    def update
      return complete_character if @step.summary?

      @character.choose_ability_method(step_params[:ability_method])
      @character.fill_step(@step, sheet_values: step_params[:sheet], name: step_params[:name], **behavior_choices)
      next_step = @character.creation_steps.after(@step)
      @character.reach_creation_step(next_step.key) if params[:go_to].blank?
      return render_step_again unless @character.save

      redirect_to destination_after_save(next_step)
    end

    # Sent in the background by autosave_controller.js while the player fills the step, and when they leave the page:
    # the draft keeps what is valid (Character#save_draft_step), nothing else changes, nothing is shown
    def draft
      unless @step.summary?
        @character.choose_ability_method(step_params[:ability_method])
        @character.save_draft_step(@step, sheet_values: step_params[:sheet], name: step_params[:name],
                                          **behavior_choices)
      end
      head :no_content
    end

    private

    def set_participation
      @participation = current_user.participations.accepted.player.find_by!(game_table_id: params[:game_table_id])
      @game_table = @participation.game_table
    end

    def redirect_if_character_complete
      redirect_to game_table_path(@game_table) unless @participation.needs_character?
    end

    def set_character
      @character = @participation.character_draft
    end

    # A step not reached yet, unknown, or gone (no spells for this class, a step renamed in the template, an old
    # bookmark) leads the player to the step they are at (decision), rather than to a page not found
    def set_step
      @step = @character.creation_steps.find(params[:step])
      return if @step && @character.creation_step_reached?(@step)

      redirect_to new_game_table_character_path(@game_table)
    end

    # For screen readers only: on screen, the page of the table follows
    def complete_character
      @character.complete_creation
      return render_step_again unless @character.save

      redirect_to game_table_path(@game_table),
                  flash: { screen_reader_notice: t(".created", name: @character.name) }
    end

    # The step named in go_to (one not reached leads back to the current one, set_step), "My tables" for Later,
    # otherwise the next step
    def destination_after_save(next_step)
      return game_tables_path(table: @game_table.id) if params[:go_to] == LATER

      game_table_character_step_path(@game_table, params[:go_to].presence || next_step.key)
    end

    def render_step_again
      @computed_sheet_values = @character.computed_sheet_values
      render :show, status: :unprocessable_content
    end

    # Nothing sent on the summary, whose button only confirms
    def step_params
      params.fetch(:character, {}).permit(:name, :ability_method, :fighting_style, sheet: {}, spell_keys: [],
                                                                                   weapon_mastery_keys: [],
                                                                                   class_choices: {}, feat_spells: {},
                                                                                   species_feat: {})
    end

    # What the behaviors of the step get beside the sheet (CreationStepBehaviors: the spells, the style, the masteries)
    def behavior_choices
      step_params.slice(:spell_keys, :fighting_style, :weapon_mastery_keys, :class_choices,
                        :feat_spells, :species_feat).to_h.symbolize_keys
    end
  end
end
