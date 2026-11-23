# The third step of a table: the spells and items of the catalog of its template it offers (Catalogs::TableCatalog),
# in two tabs (?kind=spell, ?kind=item). A tab is a submit button: changing tab saves the one shown first, nothing is
# lost. On a draft, Continue saves and opens the next step; on a table ready (its "Game settings"), Save shows the same
# tab again. Characters already made keep their copy of what they chose (decision)
module GameTables
  class CatalogsController < ApplicationController
    include TableOfGameMaster

    KINDS = %w[spell item].freeze

    before_action :set_catalog_kind

    def edit
      @catalog_entries = CatalogEntry.where(sheet_template_id: @game_table.sheet_template_id, kind: @catalog_kind)
                                     .order(:name)
      @locked_keys = @catalog_kind == "item" ? Catalogs::StartingEquipmentItemKeys.new(@game_table).call : []
    end

    def update
      Catalogs::OfferedEntriesUpdater.new(@game_table, kind: @catalog_kind).call(params[:offered_keys])
      return redirect_to tab_path(params[:go_to]) if KINDS.include?(params[:go_to])
      return redirect_to tab_path(@catalog_kind), notice: t(".saved") unless @game_table.draft?

      @game_table.reach_creation_step(GameTable.next_creation_step("catalog"))
      # For screen readers only: the next step shows
      redirect_to game_table_summary_path(@game_table), flash: { screen_reader_notice: t(".saved") }
    end

    private

    def tab_path(kind)
      edit_game_table_catalog_path(@game_table, kind: kind)
    end

    def set_catalog_kind
      @catalog_kind = KINDS.include?(params[:kind]) ? params[:kind] : KINDS.first
    end
  end
end
