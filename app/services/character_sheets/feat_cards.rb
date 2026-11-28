# The feats a character may pick, as the cards of the page (decision of 27 November, after Baldur's Gate 3): a feat that
# gives spells from a list (Magic Initiate) is one card per list, « Initié à la magie : Druide », so that the player
# never answers « which list? » apart. A list its other feats took already stays, greyed, with what took it. The value
# of a card is the key of its feat, and its list after a ~ (« magic-initiate~Druide »)
module CharacterSheets
  class FeatCards
    SEPARATOR = "~".freeze

    Card = Data.define(:value, :feat, :list, :taken_by) do
      def taken?
        taken_by.present?
      end

      def name
        list ? I18n.t("game_tables.character_steps.feat_cards.with_list", feat: feat.name, list: list) : feat.name
      end

      def list_description
        list && feat.effects.dig("spell_picks", "list_descriptions", list)
      end
    end

    # The key of the feat and its list from the value of a card (no list for a feat without spells)
    def self.split(value)
      key, list = value.to_s.split(SEPARATOR, 2)
      [key.presence, list.presence]
    end

    def self.value_of(feat_key, list)
      list ? [feat_key, list].join(SEPARATOR) : feat_key
    end

    # source: where the feat picked comes from (the species, a level), its own list never counted as taken
    def initialize(character, source:)
      @feat_spells = character.feat_spells
      @source = source
    end

    def cards(feats)
      feats.flat_map do |feat|
        lists = feat.effects.dig("spell_picks", "lists")
        lists ? Array(lists).map { |list| card(feat, list) } : [Card.new(feat.key, feat, nil, nil)]
      end
    end

    private

    def card(feat, list)
      Card.new(self.class.value_of(feat.key, list), feat, list, @feat_spells.list_taken_by(list, except: @source))
    end
  end
end
