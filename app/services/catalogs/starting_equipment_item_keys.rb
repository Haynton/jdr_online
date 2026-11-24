# The items of the starting equipment the template of a table offers (the effects starting_equipment of its lists:
# the class, the background), by key: the step "Spells and items" says so under their name, and that turning one off
# takes it out of the starting equipment of the table (decision of 24 November, before: they could not be turned off).
# An item picked in a group ("a musical instrument") is not among them
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
