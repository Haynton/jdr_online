# The templates of a game master (the template editor, first step): the list of theirs and of the predefined ones,
# then the page of one of theirs, to rename or delete it. Only the owner sees, renames or deletes a template (404 for
# anyone else, a predefined template included); a template a table uses is not deleted
class SheetTemplatesController < ApplicationController
  before_action :set_own_template, only: %i[show update destroy]

  def index
    @own_templates = current_user.sheet_templates.includes(:parent).order(:name)
    @predefined_templates = SheetTemplate.predefined.where(locale: I18n.locale.to_s).order(:name)
  end

  def show
  end

  # The field already shows the new name: the message is for screen readers only
  def update
    if @sheet_template.update(name_params)
      return redirect_to(@sheet_template, flash: { screen_reader_notice: t(".renamed") })
    end

    render :show, status: :unprocessable_content
  end

  def destroy
    return redirect_to(@sheet_template, alert: t(".used_by_tables")) if @sheet_template.used_by_tables?

    @sheet_template.destroy!
    redirect_to sheet_templates_path, flash: { screen_reader_notice: t(".deleted", name: @sheet_template.name) }
  end

  private

  def set_own_template
    @sheet_template = current_user.sheet_templates.find(params[:id])
  end

  def name_params
    params.expect(sheet_template: [:name])
  end
end
