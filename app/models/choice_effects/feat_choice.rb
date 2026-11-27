module ChoiceEffects
  # A feat the option lets the player pick at the creation (decision of 27 November, SRD 5.2.1: the trait Versatile of
  # the human, an origin feat), among the categories it names (feat_categories of the template). Asked at the step of
  # the origin feats (CreationStepBehaviors::ChoosesOriginFeats), kept in characters.feats
  class FeatChoice < Base
    KEY = "feat_choice".freeze

    def value_errors(value, **)
      return [] if value.is_a?(Hash) && value["categories"].is_a?(Array) && value["categories"].all?(String)

      [[:unknown_effect_value, { effect: KEY, value: value.to_s.truncate(60) }]]
    end
  end
end
