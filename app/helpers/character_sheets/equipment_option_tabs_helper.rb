# The options of the starting equipment as tabs (Equipment step, decision after a trial of cards: lighter, the page
# holds on the screen): "Objets", "110 pièces d'or" ("Objets A", "Objets B" when there are several), a gold line under
# the one picked. Each tab a label holding its radio: the whole tab clickable, without JavaScript too
module CharacterSheets
  module EquipmentOptionTabsHelper
    SCOPE = CharacterSheets::EquipmentChoicesHelper::SCOPE

    TABS_CLASSES = "flex gap-6 border-b border-line".freeze
    TAB_CLASSES = %w[
      -mb-px inline-flex h-9 cursor-pointer items-center border-b-2 border-transparent text-sm text-muted
      transition-colors hover:text-ink has-checked:border-brass has-checked:font-semibold has-checked:text-ink
      has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring
    ].join(" ").freeze

    def equipment_option_tab_label(choice, option)
      return t("#{SCOPE}.gold", count: option["gold"].to_i) if option["items"].blank?

      several = choice.options.count { |candidate| candidate["items"].present? } > 1
      several ? t("#{SCOPE}.items_option", letter: option["key"].upcase) : t("#{SCOPE}.items_card")
    end
  end
end
