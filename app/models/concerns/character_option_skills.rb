# The skills an option of a list that depends on another offers to pick (decision of 28 November: the College of Lore
# of the bard, 3 skills of any list), on a creation step of their own (CreationStepBehaviors::ChoosesOptionSkills),
# no longer mixed with those of the class on the step of the skills. Kept by key of the list (characters.option_skills:
# { "subclass" => ["arcana", "history"] }), ticked on the sheet, and given beside the options to the count of the class
# (CharacterSkillChoices#skill_choices: granted). Checked on its step and when the character is done: no more than the
# option offers, and only among its list
module CharacterOptionSkills
  extend ActiveSupport::Concern

  # What a list offers: the list (its field), the option picked, how many skills, and from which
  Offer = Data.define(:field, :option, :count, :from)

  included do
    # Set by the step that asks them (fill_step): only there, and when the character is done, are they checked
    attr_accessor :checks_option_skills

    validate :option_skills_allowed, if: -> { pc? && draft? && (checks_option_skills || completing_creation?) }
  end

  # The lists that depend on another (options_from: the subclass) whose option picked, asked at this level, offers
  # skills to pick
  def option_skill_offers
    sheet_fields.filter_map do |field|
      next unless field["options_from"] && FieldTypes.of(field).asked_on?(field, sheet)

      offered = field.dig("effects", sheet[field["key"]], "skill_choices")
      Offer.new(field, sheet[field["key"]], offered["count"].to_i, offered["from"].to_a) if offered
    end
  end

  # Every skill picked for an option, all lists together
  def option_skill_keys
    option_skills.to_h.values.flatten
  end

  # Which option gave each skill picked for it ({ "arcana" => "Collège du Savoir" }): the step of the skills says it on
  # its line, as for a feat
  def option_skill_sources
    option_skills.to_h.each_with_object({}) do |(field_key, keys), sources|
      Array(keys).each { |key| sources[key] ||= sheet[field_key] }
    end
  end

  # The skills sent from the step ({ "subclass" => ["arcana"] }): those of the lists that offer some, among their
  # list; the skills picked before are unticked first, the new ones ticked
  def choose_option_skills(picks)
    picks = picks.to_h.stringify_keys
    untick_skills(option_skill_keys)
    self.option_skills = option_skill_offers.to_h do |offer|
      [offer.field["key"], Array(picks[offer.field["key"]]).compact_blank.uniq & offer.from]
    end.compact_blank
    tick_skills(option_skill_keys)
  end

  # A class, a subclass or a level changed on another step drops the skills of a list that no longer offers them
  def keep_offered_option_skills
    offered = option_skill_offers.to_h { |offer| [offer.field["key"], offer.from] }
    kept = option_skills.to_h.filter_map do |key, keys|
      [key, Array(keys) & offered[key]] if offered[key]
    end.to_h.compact_blank
    untick_skills(option_skill_keys - kept.values.flatten)
    self.option_skills = kept
  end

  private

  def option_skills_allowed
    option_skill_offers.each do |offer|
      picked = Array(option_skills.to_h[offer.field["key"]])
      errors.add(:option_skills, :too_many_skills, count: offer.count) if picked.size > offer.count
    end
  end
end
