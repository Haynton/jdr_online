# The rows of cards of the Spells step (game_tables/character_steps/_spell_cards): the spells always prepared, those of
# each group of the class (the cantrips, the prepared spells, the spellbook of a wizard), then one per feat of its
# origin that gives spells (Magic Initiate, decision of 28 November: CharacterFeatSpellPicks). The first row of the
# class stays on top; the others share the row under it, one at a time, chosen by their names (decision: the page
# keeps two rows). Each row counts what it asks (counters: one per kind of spell, a slot each in the hand)
module CharacterSheets
  module CharacterSheets::SpellCardRowsHelper
    SCOPE = SpellCardsHelper::SCOPE
    # A row: key (its id), title, hint, its spells in their order, the group of the class it shows (the tag of the level
    # on a card), the spellbook, given (ticked and disabled), known (the spells a feat gives already: given cards),
    # counters, and for a feat its source and what it picked
    SpellCardRow = Data.define(:key, :title, :hint, :spells, :group, :book, :given, :known, :counters, :feat)
    # What a row counts: a kind of spell (count_for: pick, prepared, cantrips, spell), how many, how many picked; row:
    # the key of its row, whose cards it counts
    SpellCounter = Data.define(:key, :row, :count_for, :allowed, :label, :chosen)

    def spell_card_rows(character)
      choices = character.spell_choices
      decks = character.feat_spell_decks
      rows = []
      rows << always_prepared_row(choices.always_prepared) if choices.always_prepared.any?
      rows += choices.groups.map { |group| class_spell_row(character, group, decks) }
      rows + decks.map { |deck| feat_spell_row(character, deck) }
    end

    # The name of the box of a card in its row, what it counts for, whether it is ticked: [name, count_for, checked].
    # A spell given (always prepared, or by a feat elsewhere) has no name: ticked, disabled, never sent
    def spell_card_box(row, spell, character)
      return [nil, nil, true] if row.given || row.known.key?(spell.key)
      return feat_card_box(row, spell) if row.feat
      return ["character[spellbook_keys][]", "book", row.book.include?(spell.key)] if row.book

      ["character[spell_keys][]", "pick", spell_picked_for_class?(character, spell)]
    end

    # Picked for its class: a spell its feat gives (marked) is in the row of that feat
    def spell_picked_for_class?(character, spell)
      character.spells.any? { |chosen| chosen["key"] == spell.key && !chosen[FeatSpells::MARK] }
    end

    # « 1/2 »: the spells picked in a row out of those it asks, every kind counted (spell_hand_controller.js#countOf)
    def spell_row_count(row)
      "#{row.counters.sum(&:chosen)}/#{row.counters.sum(&:allowed)}"
    end

    # [["0", "Sorts mineurs"], ["1", "Niv. 1"]]: the levels a row holds, when it holds several
    def spell_row_levels(row)
      levels = row.spells.map(&:level).uniq.sort
      return [] if levels.size < 2

      levels.map do |level|
        [level.to_s, level.zero? ? t("#{SCOPE}.cantrip") : t("#{SCOPE}.level_short", level: level)]
      end
    end

    # « Grimoire : 5 sur 6 », the spells written in the book of a wizard
    def spell_cards_book_status_data(book, row)
      { spell_hand_target: "bookStatus", allowed: book.size, row: row.key,
        template: t("#{SCOPE}.book", label: book.label, chosen: "__CHOSEN__", allowed: "__ALLOWED__") }
    end

    # « 2 à choisir », « Sorts mineurs (2) : 2 à choisir » for a row that counts several kinds (a feat)
    def spell_counter_text(counter)
      [counter.label, spell_cards_left(counter.chosen, counter.allowed)].compact.join(" : ")
    end

    def spell_counter_data(counter)
      spell_cards_status_data(counter.allowed).merge(
        count_for: counter.count_for, row: counter.row, slots: counter.key,
        prefix: ("#{counter.label} : " if counter.label), invalid: ("" if counter.chosen > counter.allowed)
      ).compact
    end

    # The spells of the group picked by the character (its spells of a feat apart)
    def spell_cards_chosen_count(character, group, book: nil)
      return book.keys.size if book

      character.spells.count { |spell| !spell[CharacterSheets::FeatSpells::MARK] && group.keys.include?(spell["key"]) }
    end

    def spell_cards_status_data(allowed)
      { spell_hand_target: "status", allowed: allowed,
        left_one: t("#{SCOPE}.left", count: 1), left_other: t("#{SCOPE}.left.other", count: "__COUNT__"),
        full: t("#{SCOPE}.full"), over: t("#{SCOPE}.over", chosen: "__CHOSEN__", allowed: "__ALLOWED__") }.compact
    end

    private

    def always_prepared_row(always_prepared)
      SpellCardRow.new(key: "always_prepared", title: t("#{SpellChoicesHelper::SCOPE}.always_prepared"),
                       hint: always_prepared_spells_hint(always_prepared), spells: always_prepared.entries, group: nil,
                       book: nil, given: true, known: {}, counters: [], feat: nil)
    end

    # The spells the feats picked here already are not given cards of the class: they are picked on this page
    def class_spell_row(character, group, decks)
      book = character.spellbook_of_class
      book = nil unless book.any? && book.group.key == group.key
      picked_here = decks.flat_map { |deck| Array(deck.picks["cantrips"]) + Array(deck.picks["spell"]) }
      known = character.feat_spells.known_elsewhere(except: FeatSpells::CLASS_SOURCE).except(*picked_here)
      counter = SpellCounter.new(key: group.key, row: group.key, count_for: book ? "prepared" : "pick",
                                 allowed: group.allowed_count, label: nil,
                                 chosen: spell_cards_chosen_count(character, group))
      SpellCardRow.new(key: group.key, title: group.label, hint: spell_group_hint(group),
                       spells: in_level_order(group.spells), group: group, book: book, given: false, known: known,
                       counters: [counter], feat: nil)
    end

    def feat_spell_row(character, deck)
      offer = character.feat_spells.offer(deck.list)
      SpellCardRow.new(key: "feat_#{deck.source}", title: t("game_tables.character_steps.feat_cards.with_list",
                                                            feat: deck.feat.name, list: deck.list),
                       hint: feat_spell_row_hint(character, deck), spells: offer.cantrips + offer.spells, group: nil,
                       book: nil, given: false, known: {}, counters: feat_spell_counters(deck), feat: deck)
    end

    def feat_spell_counters(deck)
      [["cantrips", deck.settings["cantrips"], Array(deck.picks["cantrips"]).size],
       ["spell", deck.settings["level_one"], Array(deck.picks["spell"]).size]].filter_map do |kind, allowed, chosen|
        next unless allowed.to_i.positive?

        # Short, beside the marks of the strip: « Mineurs », « Niv. 1 »
        label = kind == "cantrips" ? t("#{SCOPE}.cantrips_short") : t("#{SCOPE}.level_short", level: 1)
        SpellCounter.new(key: "feat_#{deck.source}_#{kind}", row: "feat_#{deck.source}", count_for: kind,
                         allowed: allowed.to_i, label: label, chosen: chosen)
      end
    end

    # « Donné par votre historique (Sage). Vos 3 sorts viennent d'une même liste… »: where the feat comes from, and when
    # its spells change
    def feat_spell_row_hint(character, deck)
      count = deck.settings["cantrips"].to_i + deck.settings["level_one"].to_i
      [feat_spell_row_origin(character, deck),
       t("game_tables.character_steps.feat_spells.list_hint", count: count)].join(". ")
    end

    def feat_card_box(row, spell)
      kind = spell.level.zero? ? "cantrips" : "spell"
      name = "character[feat_spell_picks][#{row.feat.source}][#{kind}][]"
      [name, kind, Array(row.feat.picks[kind]).include?(spell.key)]
    end

    # By level, in the order they came within a level (the levels of the prepared spells follow each other)
    def in_level_order(spells)
      spells.each_with_index.sort_by { |spell, position| [spell.level, position] }.map(&:first)
    end
  end
end
