# A companion (a familiar, a steed, a tamed beast) is a creature of the game master given to a player character.
# Its owner may come later: at the creation of a table, the players have no character yet. The owner gone, the
# companion goes back to the game master (nullify), never deleted with them
class AddOwnerCharacterToCharacters < ActiveRecord::Migration[8.1]
  def up
    add_reference :characters, :owner_character, foreign_key: { to_table: :characters, on_delete: :nullify }

    remove_check_constraint :characters, name: "characters_kind_check"
    add_check_constraint :characters, "kind IN ('pc', 'npc', 'monster', 'companion')", name: "characters_kind_check"
    add_check_constraint :characters, "owner_character_id IS NULL OR kind = 'companion'",
                         name: "characters_owner_only_for_companion_check"
  end

  def down
    remove_check_constraint :characters, name: "characters_owner_only_for_companion_check"
    remove_check_constraint :characters, name: "characters_kind_check"
    add_check_constraint :characters, "kind IN ('pc', 'npc', 'monster')", name: "characters_kind_check"

    remove_reference :characters, :owner_character, foreign_key: { to_table: :characters }
  end
end
