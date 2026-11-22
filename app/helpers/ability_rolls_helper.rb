# "Roll the dice" of the abilities on the character sheet (ability_roll_controller.js, AbilityRollsController):
# only when the template of the table says how its abilities are rolled (character_fields.ability_roll)
module AbilityRollsHelper
  def ability_roll_available?(game_table)
    game_table.ability_roll_method.present?
  end

  # What the controller needs: where the server rolls, and the texts it writes
  def ability_roll_data(game_table)
    return {} unless ability_roll_available?(game_table)

    { controller: "ability-roll", ability_roll_url_value: game_table_ability_roll_path(game_table),
      ability_roll_reroll_label_value: t("game_tables.characters.new.reroll"),
      ability_roll_placeholder_value: t("game_tables.characters.new.place_result") }
  end

  # "4d6, keeping the 3 best", from the method of the template
  def ability_roll_method_text(game_table)
    roll_method = game_table.ability_roll_method
    t("game_tables.characters.new.roll_method", dice: roll_method["dice"], sides: roll_method["sides"],
                                                kept: roll_method.fetch("keep_highest", roll_method["dice"]))
  end
end
