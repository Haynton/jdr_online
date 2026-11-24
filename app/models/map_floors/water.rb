module MapFloors
  # Water: a river, a pond
  class Water < MapFloors::Base
    KEY = "water".freeze

    def air?
      true
    end
  end
end
