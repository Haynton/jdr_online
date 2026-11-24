# The whole catalog of the template of a table, of a kind (the spells, the items), in a window over its step "Spells
# and items": each entry with "Customize", which lists it on the step (GameTables::CatalogEntriesController#create
# copies it for the table), or "Listed" when it is already. The window stays open to pick several. Beside the search,
# the lists of the fields the template filters on (CatalogFiltersHelper)
module GameTables
  class CatalogPickersController < ApplicationController
    include TableOfGameMaster
    include VariesOnTurboFrame

    def show
      @catalog_kind = CatalogsController.kind_from(params[:kind])
      @catalog_entries = CatalogEntry.where(sheet_template_id: @game_table.sheet_template_id, kind: @catalog_kind)
                                     .sort_by { |entry| I18n.transliterate(entry.name).downcase }
      @listed_keys = Catalogs::TableCustomizations.new(@game_table).listed_keys(@catalog_kind)
      set_filters(@catalog_kind, @catalog_entries)
    end

    private

    def set_filters(kind, entries)
      fields = helpers.catalog_entry_shown_fields(@game_table, kind)
      @filter_keys = helpers.catalog_filter_keys(fields)
      @filters = helpers.catalog_filters(fields, entries)
    end
  end
end
