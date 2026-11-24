module AbilityMethods
  # Points spent on the scores (27 in all, a score of 8 free, 15 for 9 points): a score typed is one the costs name,
  # and all of them together cost no more than the points
  class PointBuy < Base
    KEY = "point_buy".freeze
    GUIDE_PARTIAL = "character_sheets/ability_methods/point_buy".freeze
    OWN_PARAMETERS = %w[points costs].freeze
    REQUIRED_PARAMETERS = %w[points costs].freeze

    def settings_errors(method, **)
      costs = method["costs"]
      valid_costs = costs.is_a?(Hash) && costs.any? &&
                    costs.all? { |score, cost| score.to_s.match?(/\A\d+\z/) && cost.is_a?(Integer) && cost >= 0 }
      return [] if positive_integer?(method["points"]) && valid_costs

      [[:invalid_point_buy, { method: method["label"] }]]
    end

    def score_errors(scores, method)
      costs = self.class.costs(method)
      outside = scores.reject { |_ability, score| costs.key?(score) }
      outside_errors = outside.map do |ability, _score|
        [[ability], :outside_point_buy, { minimum: costs.keys.min, maximum: costs.keys.max }]
      end
      outside_errors + budget_errors(scores.except(*outside.keys), costs, method["points"])
    end

    # The cost of each score, its scores as numbers ({ 8 => 0, ..., 15 => 9 })
    def self.costs(method)
      method["costs"].to_h.transform_keys(&:to_i)
    end

    private

    def budget_errors(scores, costs, points)
      spent = scores.values.sum { |score| costs[score] }
      return [] if spent <= points

      [[[], :too_many_points, { count: spent - points }]]
    end
  end
end
