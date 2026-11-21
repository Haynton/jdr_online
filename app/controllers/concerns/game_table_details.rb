# The first step of the creation of a table (name, description, cover, sheet template), shared by the new table
# form (GameTablesController) and the form of a draft (GameTables::DetailsController). Each controller declares
# its own before_action :set_available_sheet_templates: a list of actions here would name some it does not have
module GameTableDetails
  extend ActiveSupport::Concern

  private

  def game_table_details_params
    params.expect(game_table: %i[name description cover_image])
  end

  # Looked up only among the templates the user may pick: the id of another game master's template
  # counts as no choice at all, and the form asks for one
  def chosen_sheet_template
    SheetTemplate.available_to(current_user).find_by(id: params.dig(:game_table, :sheet_template_id))
  end

  # The predefined templates first (no owner), then the user's own
  def set_available_sheet_templates
    @available_sheet_templates = SheetTemplate.available_to(current_user).order(:owner_id, :name)
  end
end
