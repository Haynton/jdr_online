module GameTables
  module GameMaps
    # A creature of the bestiary the table offers, copied into the table when the game master puts its first token on
    # a map in the editor (Anthony's decision: any creature, not only those added at the step "PNJ et ennemis";
    # Catalogs::CreatureCopier, numbered like at that step). Answers the copy for the editor, which puts its token and
    # saves the map itself. Only on a map of a table of the game master (DrawnMapOfTable), a creature the table
    # offers (404 otherwise)
    class CreaturesController < ApplicationController
      include DrawnMapOfTable

      def create
        character = Catalogs::CreatureCopier.new(@game_table).call(params.expect(:key))
        render json: { id: character.id, name: character.name, kind: character.kind }, status: :created
      end
    end
  end
end
