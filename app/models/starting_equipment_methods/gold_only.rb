module StartingEquipmentMethods
  # Only the options of gold alone: the player buys their equipment themselves
  class GoldOnly < Base
    KEY = "gold_only".freeze

    private

    def keeps?(option)
      !with_items?(option)
    end
  end
end
