module MapFloors
  # A room: a plain floor, walled in ink where it meets the empty ground or open air
  class Room < MapFloors::Base
    KEY = "room".freeze
  end
end
