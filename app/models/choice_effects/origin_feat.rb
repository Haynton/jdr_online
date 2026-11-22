module ChoiceEffects
  # The origin feat of a background: its key in the future catalog, and its name, shown in the summary of the choices
  class OriginFeat < Base
    KEY = "origin_feat".freeze

    def facts(value, _fields_by_key)
      name = value.to_h["name"]
      name ? [[fact_label(:origin_feat), name]] : []
    end
  end
end
