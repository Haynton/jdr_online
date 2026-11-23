# The items of the starting equipment the template of a table offers (the effects starting_equipment of its lists:
# the class, the background), by key. They stay offered whatever the game master turns off (decision of 23 November):
# without them, the starting equipment of a character would lose a line. An item picked in a group ("a musical
# instrument") is not among them: the group keeps its other items
module Catalogs
  class StartingEquipmentItemKeys
    def initialize(game_table)
      @game_table = game_table
    end

    def call
      starting_equipment_options.flat_map { |option| option["items"].to_a }.filter_map { |line| line["key"] }.uniq
    end

    private

    def starting_equipment_options
      @game_table.character_sheet_fields.flat_map { |field| field["effects"].to_h.values }
                 .flat_map { |effects| effects.dig("starting_equipment", "options").to_a }
    end
  end
end
