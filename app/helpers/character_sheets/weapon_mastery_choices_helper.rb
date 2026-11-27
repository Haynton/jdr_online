# The cards to tick or to pick beside the fields of a step (the fighting style and the weapon masteries, the feats, the
# choices of a class, the spellbook of a level up): the shape of a card of the creation (decision, prototype "Création
# façon jeu"), a border all around and corners of 10 px; picked, a thin border chosen-line and the tonal gold
# background, no shadow; relative, so that its hidden box (sr-only) stays in it. The secondary texts (muted, brass)
# turn to the only colours allowed on primary-soft
module CharacterSheets
  module WeaponMasteryChoicesHelper
    SCOPE = "game_tables.character_steps.weapon_mastery_choices".freeze
    CARD_CLASSES = %w[
      group/pick relative flex cursor-pointer gap-3 rounded-[10px] border border-line px-4 py-3 transition-colors
      hover:border-field-line hover:bg-surface has-checked:border-chosen-line has-checked:bg-primary-soft
      has-checked:[&_.text-muted]:text-ink has-checked:[&_.text-brass]:text-primary-soft-ink
      has-focus-visible:outline-2 has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring
    ].join(" ").freeze

    # The diamond of a card whose box is hidden in it (the weapon masteries), as on the lines of the skills
    MARKER_CLASSES = %w[
      mt-1.5 size-2.5 shrink-0 rotate-45 rounded-[2px] border border-brass group-has-checked/pick:bg-brass
    ].join(" ").freeze

    # A title of the step in small capitals, as the saving throws and the skills
    TITLE_CLASSES = "float-left w-full text-xs font-bold tracking-widest text-muted uppercase".freeze

    # A kind of weapon to tick, small, under the property it gives (its box hidden in it, a diamond in its place)
    CHIP_CLASSES = %w[
      group/pick relative inline-flex h-8 cursor-pointer items-center gap-2 rounded-[10px] border border-line px-2.5
      text-sm text-ink transition-colors hover:border-field-line hover:bg-surface has-checked:border-chosen-line
      has-checked:bg-primary-soft has-checked:text-primary-soft-ink has-focus-visible:outline-2
      has-focus-visible:outline-offset-2 has-focus-visible:outline-focus-ring has-disabled:cursor-not-allowed
      has-disabled:opacity-45 has-disabled:hover:border-line has-disabled:hover:bg-transparent
    ].join(" ").freeze

    # The measures of balanced_mastery_groups, in characters and pixels of a column of 360 px
    MASTERY_COLUMNS = 3
    TITLE_HEIGHT = 20
    RULE_CHARACTERS_PER_LINE = 58
    RULE_LINE_HEIGHT = 17
    CHIP_CHARACTERS = 6
    CHIP_CHARACTERS_PER_LINE = 42
    CHIP_LINE_HEIGHT = 38

    def weapon_mastery_card_classes
      CARD_CLASSES
    end

    # The kinds of weapons by the property they give, its rule said once (decision: on each card, the eight rules
    # repeated made a list of thirty cards): [[property, rule, kinds]], in the order of the properties, then laid out
    # so that the columns of the page come out even (balanced_mastery_groups)
    def weapon_kinds_by_mastery(kinds)
      groups = kinds.group_by { |kind| [kind.mastery, kind.rule] }
                    .sort_by { |(mastery, _rule), _kinds| I18n.transliterate(mastery.to_s).downcase }
                    .map { |(mastery, rule), grouped| [mastery, rule, grouped] }
      balanced_mastery_groups(groups)
    end

    private

    # The page fills its three columns one after the other (CSS columns): the groups are shared between three piles of
    # about the same height, the tallest first, each pile kept in the order of the properties, then one pile after the
    # other (decision: a long rule beside short ones left a column much longer than the others)
    def balanced_mastery_groups(groups, columns: MASTERY_COLUMNS)
      piles = Array.new(columns) { [] }
      groups.sort_by { |group| -mastery_group_height(group) }.each do |group|
        piles.min_by { |pile| pile.sum { |placed| mastery_group_height(placed) } } << group
      end
      piles.flat_map { |pile| pile.sort_by { |group| groups.index(group) } }
    end

    # About the height of a group in a column of 360 px: its title, the lines of its rule, the lines of its weapons
    def mastery_group_height(group)
      _mastery, rule, kinds = group
      rule_lines = (rule.to_s.length / RULE_CHARACTERS_PER_LINE.to_f).ceil
      weapon_lines = (kinds.sum { |kind| kind.label.length + CHIP_CHARACTERS } / CHIP_CHARACTERS_PER_LINE.to_f).ceil
      TITLE_HEIGHT + (rule_lines * RULE_LINE_HEIGHT) + (weapon_lines * CHIP_LINE_HEIGHT)
    end
  end
end
