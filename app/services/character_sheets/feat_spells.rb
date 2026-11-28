# The spells a feat gives to pick (decision of 27 November, SRD 5.2.1: Magic Initiate, its effect spell_picks): a spell
# list among those it names (the classes of the catalog of spells: « Clerc »), an ability to cast them, so many
# cantrips and level 1 spells of that list. What was picked is kept with the feat taken (characters.feats:
# { "spell_list", "spell_ability", "cantrips", "spell" }); the character gets a copy of each spell, marked with its
# feat, that counts in no group of its class (CharacterSpellsValidator). The spells come from the catalog of its table.
# The same feat taken again takes another list, and a spell it already knows elsewhere is not picked again
module CharacterSheets
  class FeatSpells
    # What a list offers: its cantrips, its level 1 spells (catalog entries, by name)
    Offer = Data.define(:cantrips, :spells)
    MARK = "feat".freeze
    # What stands for the spells of its class among the sources of the spells it knows
    CLASS_SOURCE = "class".freeze

    # The source of a feat taken: the background, the species, or the level it was taken at ("level-4")
    def self.source_of(entry)
      entry["source"] || "level-#{entry['level']}"
    end

    # What a form sent for a feat that gives spells: its list (the one of the card picked, CharacterSheets::FeatCards,
    # or sent apart), and what was picked in that list only (the blocks of the other lists, sent without JavaScript,
    # are left out)
    def self.picks_from(params, list: nil)
      params = params.to_h.stringify_keys
      list ||= params["spell_list"]
      chosen = params.dig("by_list", list).to_h.stringify_keys.slice("spell_ability", "cantrips", "spell")
      chosen.merge("spell_list" => list).compact_blank
    end

    def initialize(character)
      @character = character
    end

    def offer(spell_list)
      @offers ||= {}
      @offers[spell_list] ||= Offer.new(cantrips: list_spells(spell_list, 0), spells: list_spells(spell_list, 1))
    end

    # The settings of a feat for that source, with only the lists no other feat it took has (SRD 5.2.1: the same feat
    # taken again takes another list)
    def open_settings(settings, source:)
      settings.merge("lists" => Array(settings["lists"]) - taken_lists(except: source))
    end

    # The lists its feats took already, but the one of that source; the background fixes its own
    def taken_lists(except: nil)
      lists = other_entries(except).filter_map { |entry| entry["spell_list"] }
      background = except == CharacterFeats::BACKGROUND_SOURCE ? nil : @character.origin_feat_spells
      (lists + Array(background&.dig(:settings, "lists"))).uniq
    end

    # What took that list already, but the feat of that source (« Initié à la magie (Acolyte) »), nil when free
    def list_taken_by(list, except: nil)
      entry = other_entries(except).find { |taken| taken["spell_list"] == list }
      return @character.feat_entry_label(entry) if entry

      background = except == CharacterFeats::BACKGROUND_SOURCE ? nil : @character.origin_feat_spells
      return unless background && Array(background[:settings]["lists"]).include?(list)

      @character.feat_entry_label("key" => background[:feat].key, "source" => CharacterFeats::BACKGROUND_SOURCE)
    end

    # The spells it knows besides those of that source, with where they come from ({ "guidance" => "Initié à la
    # magie (Acolyte)" }): its class, the spells its options always prepare, its other feats
    def known_elsewhere(except: nil)
      sources = except == CLASS_SOURCE ? [] : [[class_spell_keys, I18n.t("#{KNOWN_SCOPE}.class")]]
      sources << [always_prepared_keys, I18n.t("#{KNOWN_SCOPE}.always_prepared")]
      sources += other_entries(except).map { |entry| [keys_of(entry), @character.feat_entry_label(entry)] }
      sources.each_with_object({}) do |(keys, label), known|
        keys.each { |key| known[key] ||= label }
      end
    end

    # The errors of what was picked for a feat (its settings: spell_picks), [] when complete; known: the spells it knows
    # elsewhere, never picked again
    def errors_for(picks, settings, known: {})
      list = picks["spell_list"]
      return [:spell_list] unless Array(settings["lists"]).include?(list)
      return [:spell_ability] unless Array(settings["abilities"]).include?(picks["spell_ability"])

      offer = offer(list)
      errors = []
      errors << :cantrips unless picked?(picks["cantrips"], offer.cantrips, settings["cantrips"])
      errors << :spell unless picked?(Array(picks["spell"]), offer.spells, settings["level_one"])
      errors << :spell_known if keys_of(picks).intersect?(known.keys)
      errors
    end

    # The copies of the spells of every feat taken that gives some, marked with their feat
    def copies
      @character.feat_list.taken_entries.flat_map do |entry|
        keys = keys_of(entry)
        next [] if keys.empty? || entry["spell_list"].blank?

        offered = offer(entry["spell_list"])
        (offered.cantrips + offered.spells).select { |spell| keys.include?(spell.key) }.map do |spell|
          SpellChoices.copy_of_entry(spell).merge(MARK => entry["key"])
        end
      end
    end

    KNOWN_SCOPE = "game_tables.character_steps.feat_spells.known".freeze

    private

    def keys_of(entry)
      (Array(entry["cantrips"]) + Array(entry["spell"])).compact_blank
    end

    def other_entries(except)
      @character.feat_list.taken_entries.reject { |entry| except && self.class.source_of(entry) == except }
    end

    def class_spell_keys
      @character.spells.to_a.reject { |spell| spell[MARK] || spell["always_prepared"] }.pluck("key")
    end

    def always_prepared_keys
      @character.spell_choices.always_prepared.keys
    end

    def picked?(keys, offered, count)
      keys = Array(keys).compact_blank
      keys.uniq.size == count.to_i && (keys - offered.map(&:key)).empty?
    end

    def list_spells(spell_list, level)
      Catalogs::TableCatalog.new(@character.game_table).entries("spell").for_class(spell_list).of_level(level)
                            .by_level_and_name.to_a
    end
  end
end
