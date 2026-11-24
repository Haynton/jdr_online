# The bestiary of a table, in a window over its step "NPCs and enemies": the creatures of the catalog of its template
# the table offers (Catalogs::TableCatalog), by challenge rating, each with "Add" (GameTables::NpcsController#create,
# which copies it). The window stays open to add several
module GameTables
  class BestiariesController < ApplicationController
    include TableOfGameMaster
    include VariesOnTurboFrame

    def show
      @creatures = Catalogs::TableCatalog.new(@game_table).entries("monster").to_a
    end
  end
end
