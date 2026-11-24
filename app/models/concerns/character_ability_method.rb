# How a character gets the scores of its abilities (AbilityMethods): the way of its table, or the one the player picked
# when the table leaves it to them, and its check on the step that asks the scores (CharacterAbilityMethodValidator)
module CharacterAbilityMethod
  extend ActiveSupport::Concern

  included do
    # Set by a step that asks the scores of the abilities (fill_step): only there are they checked against the way to
    # get them, so that a way changed by the table never stops another step
    attr_accessor :checks_ability_method

    validates_with CharacterAbilityMethodValidator
  end

  # The way this character gets the scores of its abilities, as the template declares it: the one of the table, or,
  # when the table leaves it to the player, the one they picked (the first way of the template until they pick one)
  def ability_method_in_use
    table = game_table
    return table.ability_method_of(table.ability_method_choice) unless table.players_choose_ability_method?

    table.ability_method_of(ability_method) || table.ability_methods.first
  end

  # The way to get the scores the player picked on the abilities step, when the table leaves it to them: only one the
  # template offers
  def choose_ability_method(type)
    return unless game_table.players_choose_ability_method? && game_table.ability_method_of(type)

    self.ability_method = type
  end

  # The scores typed, by ability: what an error of all the scores together reads (too many points spent,
  # CharacterAbilityMethodValidator)
  def ability_scores
    sheet.slice(*game_table.ability_fields.pluck("key"))
  end

  private

  # An error of all the scores together (too many points spent): every score goes back
  def restore_ability_scores(saved_sheet)
    game_table.ability_fields.each { |field| restore_sheet_value(field["key"], saved_sheet) }
  end
end
