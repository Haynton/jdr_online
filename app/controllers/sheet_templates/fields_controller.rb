module SheetTemplates
  # The template editor, the fields of the character sheet: their list by section, then the form of one of them, to
  # change its settings (SheetTemplates::FieldUpdater). Only on a template of the game master (404 for a predefined
  # one or the template of another game master), and only a field of its character sheet (404 for an unknown key)
  class FieldsController < ApplicationController
    before_action :set_own_template
    before_action :set_field, only: %i[edit update]

    def index
    end

    def edit
      @form_context = form_context({})
    end

    # The list shows the field as saved: the message is for screen readers only
    def update
      updater = SheetTemplates::FieldUpdater.new(sheet_template: @sheet_template, field_key: @field["key"],
                                                 submitted_values: field_params)
      if updater.call
        return redirect_to(sheet_template_fields_path(@sheet_template),
                           flash: { screen_reader_notice: t(".updated", label: updated_label) })
      end

      @form_context = form_context(field_params)
      render :edit, status: :unprocessable_content
    end

    private

    def set_own_template
      @sheet_template = current_user.sheet_templates.find(params[:sheet_template_id])
    end

    def set_field
      @field = @sheet_template.character_fields.to_h["fields"].to_a.find { |field| field["key"] == params[:key] }
      raise ActiveRecord::RecordNotFound unless @field
    end

    # Only the settings this field may change (its type says which)
    def field_params
      params.fetch(:field, {}).permit(*SheetTemplates::FieldUpdater.editable_parameters(@field)).to_h
    end

    # What the form needs (SheetTemplates::FieldFormHelper): the field, the fields it may name (as saved), and what was
    # just typed when the template refused it
    def form_context(submitted_values)
      { field: @field, fields: @sheet_template.character_fields_in_database.to_h["fields"].to_a,
        submitted: submitted_values }
    end

    def updated_label
      @sheet_template.character_fields["fields"].find { |field| field["key"] == @field["key"] }["label"]
    end
  end
end
