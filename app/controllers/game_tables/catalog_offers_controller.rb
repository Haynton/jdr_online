# The switch of a line of the step "Spells and items": offers the entry to the players or turns it off for the table
# (Catalogs::OfferedEntriesUpdater). Back to the list, refreshed by morphing where it was
module GameTables
  class CatalogOffersController < ApplicationController
    include TableOfGameMaster

    def update
      kind = CatalogsController.kind_from(params[:kind])
      Catalogs::OfferedEntriesUpdater.new(@game_table, kind: kind)
                                     .call(params[:catalog_entry_key], offered: params[:offered] == "1")
      redirect_to edit_game_table_catalog_path(@game_table, kind: kind)
    end
  end
end
