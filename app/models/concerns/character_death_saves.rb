# The death saving throws of a player's character (decision of 26 November), as its template declares them
# (character_fields.death_saves, SheetTemplates::DeathSavesCheck): at 0 hit points, a roll each turn, by its player or
# the game master; the roll that succeeds and above, a success, below a failure; critical_failure counts as two
# failures, critical_success gives back 1 hit point. needed successes: stable; needed failures: dead. A hit taken at 0
# hit points is a failure, and with massive_damage, what is left of a hit after 0 that reaches the maximum of the hit
# points kills at once. Hit points again above 0 (a heal, a rest), the successes and the failures go. They are kept in
# two number fields of the sheet (successes_from, failures_from)
module CharacterDeathSaves
  extend ActiveSupport::Concern

  included do
    before_save :clear_death_saves, if: :death_saves_to_clear?
  end

  def death_saves_settings
    game_table&.death_saves if pc?
  end

  def death_save_successes
    death_save_count("successes_from")
  end

  def death_save_failures
    death_save_count("failures_from")
  end

  def death_saves_needed
    death_saves_settings["needed"].to_i
  end

  def at_zero_hit_points?
    hit_points.present? && hit_points["current"].zero?
  end

  def dead?
    death_saves_settings.present? && death_save_failures >= death_saves_needed
  end

  def stable?
    death_saves_settings.present? && at_zero_hit_points? && !dead? && death_save_successes >= death_saves_needed
  end

  def dying?
    death_saves_settings.present? && at_zero_hit_points? && !dead? && !stable?
  end

  # What the roll does: :revived (1 hit point back), :critical_failure (two failures), :success or :failure
  def take_death_save(roll)
    settings = death_saves_settings
    return revive if settings["critical_success"] && roll >= settings["critical_success"]
    return add_death_save("failures_from", 2) && :critical_failure if critical_failure?(settings, roll)
    return add_death_save("successes_from", 1) && :success if roll >= settings["success_from"].to_i

    add_death_save("failures_from", 1) && :failure
  end

  private

  def death_save_count(parameter)
    sheet.to_h[death_saves_settings[parameter]].to_i
  end

  def critical_failure?(settings, roll)
    settings["critical_failure"] && roll <= settings["critical_failure"]
  end

  def add_death_save(parameter, count)
    total = [death_save_count(parameter) + count, death_saves_needed].min
    self.sheet = sheet.to_h.merge(death_saves_settings[parameter] => total)
  end

  def revive
    self.sheet = sheet.to_h.merge(hit_points_field["key"] => hit_points.merge("current" => 1))
    clear_death_saves
    :revived
  end

  # Called by CharacterVitals#change_hit_points with the hit points before the hit and the loss left once the temporary
  # ones took their part: at 0 already, a failure; past 0, what is left of the hit kills when it reaches the maximum
  def follow_death_saves(previous_hit_points, delta)
    return unless death_saves_settings && delta.negative? && at_zero_hit_points?

    if killed_at_once?(previous_hit_points, -delta)
      add_death_save("failures_from", death_saves_needed)
    elsif previous_hit_points.zero?
      add_death_save("failures_from", 1)
    end
  end

  def killed_at_once?(previous_hit_points, damage)
    death_saves_settings["massive_damage"] && damage - previous_hit_points >= hit_points["max"]
  end

  def death_saves_to_clear?
    death_saves_settings.present? && hit_points.present? && hit_points["current"].positive? &&
      (death_save_successes.positive? || death_save_failures.positive?)
  end

  def clear_death_saves
    self.sheet = sheet.to_h.except(death_saves_settings["successes_from"], death_saves_settings["failures_from"])
  end
end
