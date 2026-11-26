# The resources of a player's character (decision of 26 November): those the options it picked give (the class, the
# subclass: ChoiceEffects::Resources), at the level of the character, spent in the game room by its player or the game
# master and given back by a rest as the template declares. What is spent is kept by key in resources_used; the total
# is worked out, never stored, so that a level gained gives more at once
module CharacterResources
  extend ActiveSupport::Concern

  # A resource as it stands: its total at this level, how many are spent, how it comes back
  Resource = Data.define(:key, :label, :total, :used, :recovery, :pool, :short_rest_from_level) do
    def left
      total - used
    end
  end

  def resources
    return [] unless pc?

    level = spell_choices.level
    declared_resources.filter_map { |declared| resource_at(declared, level) }
  end

  def resource(key)
    resources.find { |candidate| candidate.key == key }
  end

  # amount spent when positive, given back when negative. The error, nil once changed (not saved here)
  def change_resource(resource, amount)
    used = resource.used + amount
    return :not_enough if used > resource.total
    return :nothing_spent if used.negative?

    self.resources_used = resources_used.to_h.merge(resource.key => used)
    nil
  end

  # Each resource as its template declares: all back, one back, or nothing until a long rest (unless it also comes
  # back after a short rest from a level: the bardic inspiration)
  def take_short_rest
    level = spell_choices.level
    resources.each do |resource|
      recovery = short_rest_recovery(resource, level)
      next unless recovery

      self.resources_used = resources_used.to_h.merge(resource.key => recovery == :all ? 0 : [resource.used - 1, 0].max)
    end
  end

  def give_back_resources
    self.resources_used = {}
  end

  private

  # The resources of every option picked in a list of the sheet (the class and its subclass), in their order
  def declared_resources
    sheet_fields.select { |field| field["type"] == "choice" && field["effects"] }.flat_map do |field|
      Array(field.dig("effects", sheet.to_h[field["key"]].to_s, "resources"))
    end
  end

  def resource_at(declared, level)
    total = resource_total(declared, level)
    return if total.nil? || total <= 0

    Resource.new(key: declared["key"], label: declared["label"], total: total,
                 used: resources_used.to_h[declared["key"]].to_i.clamp(0, total), recovery: declared["recovery"],
                 pool: declared["pool"] == true, short_rest_from_level: declared["short_rest_from_level"])
  end

  # The table of the level, or the modifier of an ability (at least 1) from its level
  def resource_total(declared, level)
    return declared["uses"][level - 1] if declared["uses"]
    return 0 if level < declared.fetch("from_level", 1)

    [computed_sheet_values[:modifiers][declared["uses_from"]].to_i, 1].max
  end

  def short_rest_recovery(resource, level)
    case resource.recovery
    when "short_rest" then :all
    when "short_rest_one" then :one
    else :all if resource.short_rest_from_level && level >= resource.short_rest_from_level
    end
  end
end
