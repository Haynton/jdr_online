module MapFloors
  # Open ground, grass and dirt, without walls
  class OpenAir < MapFloors::Base
    KEY = "open_air".freeze
  end
end
