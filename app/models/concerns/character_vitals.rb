# What changes on a character during the game, saved (decision of 26 November: the game master changes it from the
# quick sheet of a player, the player on their own panel « Ma fiche »): its hit points, its temporary hit points, its
# switches granted in play (the inspiration), the numbers the game master adjusts (game_master_adjusts: the bonus to
# the armour class) and a long rest. Every field is the template's, found by what it
# declares, never by its key (rule of the project): the field that takes the damage (receives_damage), the one that
# takes it first (absorbs_damage_for), the yes or no not asked at the creation (at_creation: false), what a rest does
# to each field (on_rest)
module CharacterVitals
  extend ActiveSupport::Concern

  # A box holds a few digits
  TEMPORARY_HIT_POINTS_MAX = 999
  # The bound of a number adjusted by the game master without its own min or max
  ADJUSTED_LIMIT = 99
  # What a rest does to a field, by the value of its on_rest: one method each, written once
  REST_EFFECTS = { "reset_to_max" => :rest_to_maximum, "turn_off" => :rest_turned_off }.freeze

  def hit_points_field
    sheet_fields.find { |field| field["receives_damage"] }
  end

  def temporary_hit_points_field
    damage_field = hit_points_field
    damage_field && sheet_fields.find { |field| field["absorbs_damage_for"] == damage_field["key"] }
  end

  def play_switch_fields
    sheet_fields.select { |field| field["type"] == "boolean" && field["at_creation"] == false }
  end

  # The numbers the game master adjusts in play (game_master_adjusts: the bonus to the armour class)
  def adjusted_fields
    sheet_fields.select { |field| field["type"] == "number" && field["game_master_adjusts"] }
  end

  def adjusted_value(field)
    value = sheet.to_h[field["key"]]
    value.is_a?(Integer) ? value : 0
  end

  # Within the bounds of the field; back at 0, the value goes from the sheet
  def adjust(key, delta)
    field = adjusted_fields.find { |candidate| candidate["key"] == key }
    return unless field

    value = (adjusted_value(field) + delta).clamp(field["min"] || -ADJUSTED_LIMIT, field["max"] || ADJUSTED_LIMIT)
    write_sheet_value(field, value.zero? ? nil : value)
  end

  def hit_points
    resource_value(hit_points_field)
  end

  # What is left of the hit points, from 0 to 100: the ring of the portrait, the bar of the sheet
  def hit_points_percent
    points = hit_points
    return unless points && points["max"].positive?

    (100.0 * points["current"] / points["max"]).round
  end

  def temporary_hit_points
    resource_value(temporary_hit_points_field)&.fetch("current", 0).to_i
  end

  def switched_on?(field)
    sheet.to_h[field["key"]] == true
  end

  # A loss takes the temporary hit points first (the rule of the template: absorbs_damage_for); a gain never goes
  # past the maximum
  def change_hit_points(delta)
    return unless hit_points

    previous = hit_points["current"]
    delta = absorb_with_temporary_hit_points(delta) if delta.negative?
    current = (hit_points["current"] + delta).clamp(0, hit_points["max"])
    write_sheet_value(hit_points_field, hit_points.merge("current" => current))
    follow_death_saves(previous, delta)
  end

  def change_temporary_hit_points(delta)
    give_temporary_hit_points(temporary_hit_points + delta)
  end

  def give_temporary_hit_points(amount)
    field = temporary_hit_points_field
    return unless field

    amount = amount.to_i.clamp(0, TEMPORARY_HIT_POINTS_MAX)
    write_sheet_value(field, amount.positive? ? { "current" => amount, "max" => amount } : nil)
  end

  def switch(key, switched_on)
    field = play_switch_fields.find { |candidate| candidate["key"] == key }
    write_sheet_value(field, switched_on) if field
  end

  # What a rest does to each field, as the template declares it (on_rest, FieldParameters::CHOICES)
  def take_long_rest
    sheet_fields.each do |field|
      rest_effect = REST_EFFECTS[field["on_rest"]]
      send(rest_effect, field) if rest_effect
    end
  end

  private

  def resource_value(field)
    value = field && sheet.to_h[field["key"]]
    value if value.is_a?(Hash)
  end

  def absorb_with_temporary_hit_points(delta)
    temporary = temporary_hit_points
    return delta unless temporary.positive?

    absorbed = [temporary, -delta].min
    give_temporary_hit_points(temporary - absorbed)
    delta + absorbed
  end

  def rest_to_maximum(field)
    value = resource_value(field)
    write_sheet_value(field, value.merge("current" => value["max"])) if value
  end

  def rest_turned_off(field)
    write_sheet_value(field, false)
  end

  def write_sheet_value(field, value)
    self.sheet = value.nil? ? sheet.to_h.except(field["key"]) : sheet.to_h.merge(field["key"] => value)
  end
end
