# The skills a character picks, and their check when the table limits them to what the class offers
# (GameTable#limit_skill_choices, step Settings): only on the step that asks the skills (CharacterSkillChoicesValidator)
module CharacterSkillChoices
  extend ActiveSupport::Concern

  included do
    # Set by a step that asks the skills (fill_step): only there are they checked, so that a class changed on another
    # step never stops that step
    attr_accessor :checks_skill_choices

    validates_with CharacterSkillChoicesValidator
    validates_with CharacterExpertiseValidator
  end

  def skill_choices
    CharacterSheets::SkillChoices.new(fields: sheet_fields, sheet: sheet,
                                      granted: Array(feats).flat_map { |entry| Array(entry["skills"]) })
  end

  # What its options and feats give stays ticked (the rules of the game: a barbarian always has its saving throw of
  # Strength), unless the table lets the players change it (GameTable#players_change_given_choices); an expertise stays
  def keep_given_ticked
    return if game_table.players_change_given_choices

    given = skill_choices.given_by.keys + feat_list.skill_keys
    self.sheet = sheet.merge(given.index_with { |key| FieldTypes::Bonus.expertise?(sheet[key]) ? sheet[key] : true })
  end

  # A box the player cannot untick: given by an option or a feat, on a table that keeps it (keep_given_ticked)
  def given_locked?(field_key)
    return false if game_table.players_change_given_choices

    skill_choices.given_by.key?(field_key) || feat_list.skill_keys.include?(field_key)
  end
end
