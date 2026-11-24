module StartingEquipmentMethods
  # Only the options with items (the little gold that comes with them too): no option of gold alone
  class ItemsOnly < Base
    KEY = "items_only".freeze

    private

    def keeps?(option)
      with_items?(option)
    end
  end
end
