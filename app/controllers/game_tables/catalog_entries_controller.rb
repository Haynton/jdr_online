# One spell or item of the catalog of a table (step "Spells and items"), in a window over the list
# (GameTables::CatalogEntryDialogHelper): every value the template declares for its kind, in the fields of a sheet.
# Changing an entry of the template changes it for the table only: the table gets its copy, same key
# (Catalogs::TableCatalog puts it in place of the original); "Restore the original" deletes that copy. An entry the
# game master added (decision: from an empty window) belongs to the table; deleting it removes it.
# Saved in the window: the list behind is refreshed; refused: the errors stay in the window. Characters already made
# keep their copy of what they chose (decision)
module GameTables
  class CatalogEntriesController < ApplicationController
    include TableOfGameMaster
    include CatalogEntryDialogHelper

    before_action :set_catalog_kind
    before_action :set_entry, only: %i[edit update destroy]
    after_action :vary_on_turbo_frame

    def new
      @entry = @game_table.catalog_entries.build(kind: @catalog_kind)
    end

    def create
      @entry = @game_table.catalog_entries.build(kind: @catalog_kind)
      @entry.key = Catalogs::NewEntryKey.new(@game_table, kind: @catalog_kind).call(entry_params[:name])
      save_entry(:new)
    end

    def edit
    end

    def update
      @entry = copy_for_the_table(@entry) if template_entry?
      save_entry(:edit)
    end

    def destroy
      @game_table.catalog_entries.find_by!(kind: @catalog_kind, key: params[:key]).destroy!
      show_list
    end

    private

    def set_catalog_kind
      @catalog_kind = CatalogsController::KINDS.include?(params[:kind]) ? params[:kind] : CatalogsController::KINDS.first
    end

    # The table's own entry of this key (a copy or an entry added), otherwise the one of its template
    def set_entry
      @entry = @game_table.catalog_entries.find_by(kind: @catalog_kind, key: params[:key]) ||
               CatalogEntry.find_by!(sheet_template_id: @game_table.sheet_template_id, kind: @catalog_kind,
                                     key: params[:key])
    end

    def template_entry?
      @entry.game_table_id.nil?
    end

    # The copy of an entry of the template that the table changes: same kind, key and values, owned by the table
    def copy_for_the_table(entry)
      @game_table.catalog_entries.build(kind: entry.kind, key: entry.key, name: entry.name,
                                        description: entry.description, properties: entry.properties)
    end

    def save_entry(form_action)
      @entry.assign_attributes(name: entry_params[:name], description: entry_params[:description],
                               properties: submitted_properties)
      return show_list if @entry.save

      render form_action, status: :unprocessable_content
    end

    # Each value converted by the type of its field (CharacterSheets::Builder, as on a character sheet), then checked
    # by CatalogPropertiesValidator. A property not shown in the window (internal: the group of an item) is kept
    def submitted_properties
      fields = catalog_entry_shown_fields(@game_table, @catalog_kind)
      shown = CharacterSheets::Builder.new(fields: fields, submitted_values: entry_params[:properties]).call
      @entry.properties.to_h.except(*fields.pluck("key")).merge(shown)
    end

    def entry_params
      params.fetch(:catalog_entry, {}).permit(:name, :description, properties: {})
    end

    # In the window: the list behind is drawn again, where it was. Opened directly: back to the list
    def show_list
      return render(turbo_stream: turbo_stream.refresh(request_id: nil)) if catalog_entry_in_dialog?

      redirect_to edit_game_table_catalog_path(@game_table, kind: @catalog_kind)
    end

    # The same address answers for the window or the whole page: a cache must keep them apart
    def vary_on_turbo_frame
      response.headers["Vary"] = [response.headers["Vary"], "Turbo-Frame"].compact.join(", ")
    end
  end
end
