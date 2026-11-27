# The level the game master gives a player's character in the game room (decision of 26 November): the player then
# makes the choices of that level in a window of the room (LevelUp), and the character reaches it. Empty while no
# level waits; one level at a time
class AddLevelUpToToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :level_up_to, :integer
    add_check_constraint :characters, "level_up_to BETWEEN 2 AND 20", name: "characters_level_up_to_check"
  end
end
