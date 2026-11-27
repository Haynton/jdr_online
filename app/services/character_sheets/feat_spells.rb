# The spells a feat gives to pick (decision of 27 November, SRD 5.2.1: Magic Initiate, its effect spell_picks): a spell
# list among those it names (the classes of the catalog of spells: « Clerc »), an ability to cast them, so many
# cantrips and level 1 spells of that list. What was picked is kept with the feat taken (characters.feats:
# { "spell_list", "spell_ability", "cantrips", "spell" }); the character gets a copy of each spell, marked with its
# feat, that counts in no group of its class (CharacterSpellsValidator). The spells come from the catalog of its table
module CharacterSheets
  class FeatSpells
    # What a list offers: its cantrips, its level 1 spells (catalog entries, by name)
    Offer = Data.define(:cantrips, :spells)
    MARK = "feat".freeze

    # What a form sent for a feat that gives spells: its list, and what was picked in that list only (the blocks of the
    # other lists, sent without JavaScript, are left out)
    def self.picks_from(params)
      params = params.to_h.stringify_keys
      list = params["spell_list"]
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

    # The errors of what was picked for a feat (its settings: spell_picks), [] when complete
    def errors_for(picks, settings)
      list = picks["spell_list"]
      return [:spell_list] unless Array(settings["lists"]).include?(list)
      return [:spell_ability] unless Array(settings["abilities"]).include?(picks["spell_ability"])

      offer = offer(list)
      errors = []
      errors << :cantrips unless picked?(picks["cantrips"], offer.cantrips, settings["cantrips"])
      errors << :spell unless picked?(Array(picks["spell"]), offer.spells, settings["level_one"])
      errors
    end

    # The copies of the spells of every feat taken that gives some, marked with their feat
    def copies
      @character.feat_list.taken_entries.flat_map do |entry|
        keys = Array(entry["cantrips"]) + Array(entry["spell"])
        next [] if keys.empty? || entry["spell_list"].blank?

        offered = offer(entry["spell_list"])
        (offered.cantrips + offered.spells).select { |spell| keys.include?(spell.key) }.map do |spell|
          SpellChoices.copy_of_entry(spell).merge(MARK => entry["key"])
        end
      end
    end

    private

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
