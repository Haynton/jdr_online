# The third step of a table: the spells and items it customizes (decision of 24 November): every entry of the catalog
# of its template is offered at first, and the step lists only what the game master changed, added or turned off
# (Catalogs::TableCustomizations), one tab per kind (?kind=spell, ?kind=item). "Customize a spell" opens the whole
# catalog in a window (GameTables::CatalogPickersController); each line saves as it changes (its switch, its window).
# Continue opens the next step, and reaches it on a draft. Characters already made keep their copy of what they chose,
# until the game master applies the changes to them (GameTables::CatalogApplicationsController)
module GameTables
  class CatalogsController < ApplicationController
    include TableOfGameMaster

    KINDS = %w[spell item].freeze

    # The kind asked (?kind=item), the spells otherwise
    def self.kind_from(param)
      KINDS.include?(param) ? param : KINDS.first
    end

    before_action :set_catalog_kind, only: :edit

    def edit
      @customizations = Catalogs::TableCustomizations.new(@game_table).list(@catalog_kind)
      @offered_count = Catalogs::TableCatalog.new(@game_table).entries(@catalog_kind).count
      @characters_to_update_count = Catalogs::CharacterCopiesUpdater.new(@game_table).characters_to_update.size
    end

    def update
      @game_table.reach_creation_step(GameTable.next_creation_step("catalog"))
      # For screen readers only: the next step shows
      redirect_to edit_game_table_cast_path(@game_table), flash: { screen_reader_notice: t(".saved") }
    end

    private

    def set_catalog_kind
      @catalog_kind = self.class.kind_from(params[:kind])
    end
  end
end
