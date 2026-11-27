module SheetTemplates
  # The fighting styles of the template (character_fields.fighting_styles), when it declares them: each a key, a label
  # and its rule (help), and effects from a closed list (EFFECTS: what the server works out); and every style an option
  # offers (the effect fighting_style of a class) is one of them
  class FightingStylesCheck < Check
    PARAMETERS = %w[key label help effects].freeze
    # The effects a style may have: a bonus to the attacks with a ranged weapon, to the armour class while armoured
    EFFECTS = %w[ranged_attack_bonus armored_armor_class_bonus].freeze

    def call
      styles = @sheet_template.character_fields.to_h["fighting_styles"]
      return [] if styles.nil?
      return [[:invalid_fighting_styles, {}]] unless styles.is_a?(Array)

      styles.flat_map { |style| style_errors(style) } + offered_errors(styles)
    end

    private

    def style_errors(style)
      return [[:invalid_fighting_styles, {}]] unless style.is_a?(Hash)

      unknown = (style.keys - PARAMETERS).map { |parameter| [:unknown_fighting_style_parameter, { parameter: }] }
      unknown + name_errors(style) + effect_errors(style)
    end

    def name_errors(style)
      return [] if valid_key?(style["key"]) && valid_label?(style["label"])

      [[:invalid_fighting_style, { style: style["key"].to_s }]]
    end

    def effect_errors(style)
      effects = style["effects"].to_h
      return [] if (effects.keys - EFFECTS).empty? && effects.values.all?(Integer)

      [[:invalid_fighting_style, { style: style["key"].to_s }]]
    end

    def offered_errors(styles)
      keys = styles.filter_map { |style| style["key"] if style.is_a?(Hash) }
      character_fields.select { |field| field["effects"] }.flat_map do |field|
        field["effects"].flat_map do |option, effects|
          (Array(effects.to_h.dig("fighting_style", "options")) - keys).map do |style|
            [:unknown_fighting_style, context("character_fields", field).merge(option: option, style: style)]
          end
        end
      end
    end
  end
end
