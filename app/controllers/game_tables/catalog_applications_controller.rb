# "Apply to the characters already made", on the step "Spells and items": the spells and items the game master changed
# for the table replace the copies its characters keep (Catalogs::CharacterCopiesUpdater). Back to the step, with a
# bubble saying how many characters changed (nothing else on the page shows it)
module GameTables
  class CatalogApplicationsController < ApplicationController
    include TableOfGameMaster

    def create
      kind = CatalogsController.kind_from(params[:kind])
      updated_count = Catalogs::CharacterCopiesUpdater.new(@game_table).call
      message = updated_count.zero? ? t(".already_applied") : t(".applied", count: updated_count)
      redirect_to edit_game_table_catalog_path(@game_table, kind: kind), notice: message
    end
  end
end
