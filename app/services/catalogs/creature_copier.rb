# Copies a creature of the bestiary (a catalog entry of kind monster, as the table offers it: Catalogs::TableCatalog)
# into a game table, as an enemy of its own (a character of kind monster), which the game master may change without
# touching the bestiary. The same creature added again is numbered (decision: "Gobelin", "Gobelin 2", "Gobelin 3", each
# with its own hit points). Hidden from the players until the game master shows it (an encounter stays a surprise).
# Only the values the NPC sheet of the table declares are kept: a template changed since the table copied it may have
# others
module Catalogs
  class CreatureCopier
    def initialize(game_table)
      @game_table = game_table
    end

    # The enemy saved, or raises ActiveRecord::RecordNotFound for a creature the table does not offer
    def call(creature_key)
      creature = TableCatalog.new(@game_table).entries("monster").find_by!(key: creature_key)
      @game_table.characters.create!(kind: :monster, name: free_name(creature.name), visible_to_players: false,
                                     sheet: creature.properties.slice(*npc_field_keys))
    end

    private

    def npc_field_keys
      @game_table.npc_sheet_fields.pluck("key")
    end

    # The name of the creature, then the first number free among the enemies of the table, cut to the length of a name
    def free_name(creature_name)
      taken = @game_table.npcs.pluck(:name)
      return creature_name unless taken.include?(creature_name)

      number = (2..).find { |candidate| taken.exclude?(numbered(creature_name, candidate)) }
      numbered(creature_name, number)
    end

    def numbered(creature_name, number)
      suffix = " #{number}"
      "#{creature_name.first(Character::NAME_MAX_LENGTH - suffix.length)}#{suffix}"
    end
  end
end
