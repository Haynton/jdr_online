module SheetTemplates
  # The template editor: renames a creation step from the creation path (SheetTemplates::CreationStepRenamer), saved
  # live. Only on a template of the game master (404 otherwise, and for a step it does not have). The path shows the
  # name saved: the message is for screen readers only; a refused name shows the errors over the path as saved
  class CreationStepsController < ApplicationController
    def update
      @sheet_template = current_user.sheet_templates.find(params[:sheet_template_id])
      raise ActiveRecord::RecordNotFound unless step_exists?

      renamer = SheetTemplates::CreationStepRenamer.new(sheet_template: @sheet_template, step_key: params[:key],
                                                        label: params[:label])
      return redirect_to_path if renamer.call

      @refusals = @sheet_template.errors.full_messages
      @sheet_template.reload
      render "sheet_templates/fields/index", status: :unprocessable_content
    end

    private

    def step_exists?
      @sheet_template.character_fields.to_h["creation_steps"].to_a.any? { |step| step["key"] == params[:key] }
    end

    def redirect_to_path
      redirect_to sheet_template_fields_path(@sheet_template),
                  flash: { screen_reader_notice: t("sheet_templates.creation_steps.update.renamed") }
    end
  end
end
