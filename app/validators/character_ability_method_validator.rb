# Checks the scores a player typed on a character being made against the way the table (or the player) picked to get
# them (Character#ability_method_in_use, AbilityMethods): the standard array places its values once each, the point buy
# stays within its scores and its points; a roll stays free, unless the table turns the scores typed off. Only on the
# step that asks the scores, while the character is made (Character#checks_ability_method): a way the table changes
# later never stops another step. Errors go under each ability refused, so that a draft saved in the background keeps
# its scores from before (Character#save_draft_step); one about all the scores (too many points) on ability_scores,
# shown in the guide
class CharacterAbilityMethodValidator < ActiveModel::Validator
  def validate(character)
    return unless character.checks_ability_method && character.pc? && character.draft? && character.game_table

    method = with_roll_kept(character, character.ability_method_in_use)
    return unless method

    scores = typed_scores(character)
    AbilityMethods.find(method["type"]).score_errors(scores, method).each do |ability_keys, error_type, options|
      add_error(character, ability_keys, error_type, options)
    end
  end

  private

  # The totals of the roll kept, when the table turns the scores typed by hand off (AbilityMethods::Roll)
  def with_roll_kept(character, method)
    return method unless method&.dig("type") == AbilityMethods::Roll::KEY && !character.game_table.ability_scores_typed

    method.merge("rolled" => Array(character.ability_rolls).pluck("total"))
  end

  def typed_scores(character)
    character.game_table.ability_fields.pluck("key")
             .index_with { |key| character.sheet[key] }.select { |_key, score| score.is_a?(Integer) }
  end

  def add_error(character, ability_keys, error_type, options)
    return character.errors.add(:ability_scores, error_type, **options) if ability_keys.empty?

    ability_keys.each { |key| character.errors.add(:"sheet.#{key}", error_type, **options) }
  end
end
