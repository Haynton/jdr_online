module SheetTemplates
  # The price lists of the template (character_fields.price_lists, decision of 27 November): what is paid without being
  # carried (a night at the inn, a lifestyle, a hireling, a spell cast for you), shown to the game master in the game
  # room. A list where each price list has a key (unique), a label and its lines, each line a label, a price written
  # in the words of the game (« 5 pa ») and, if needed, a short note (« ville seulement »)
  class PriceListsCheck < Check
    PARAMETERS = %w[key label lines].freeze
    LINE_PARAMETERS = %w[label price note].freeze
    PRICE_MAX_LENGTH = 30
    NOTE_MAX_LENGTH = 120

    def call
      lists = @sheet_template.character_fields.to_h["price_lists"]
      return [] if lists.nil?
      return [[:invalid_price_lists, {}]] unless lists.is_a?(Array) && lists.all?(Hash)

      lists.flat_map { |list| list_errors(list) } + duplicate_errors(lists)
    end

    private

    def list_errors(list)
      name = list["label"].presence || list["key"].to_s
      unknown = (list.keys - PARAMETERS).map do |parameter|
        [:unknown_price_list_parameter, { list: name, parameter: parameter }]
      end
      unknown + key_and_label_errors(list) + lines_errors(list["lines"], name)
    end

    def key_and_label_errors(list)
      key = list["key"].to_s
      errors = valid_key?(list["key"]) ? [] : [[:invalid_price_list_key, { key: key }]]
      return errors if valid_label?(list["label"])

      errors + [[:invalid_price_list_label, { key: key, count: LABEL_MAX_LENGTH }]]
    end

    def lines_errors(lines, name)
      return [[:invalid_price_lines, { list: name }]] unless lines.is_a?(Array) && lines.any? && lines.all?(Hash)
      return [] if lines.all? { |line| valid_line?(line) }

      [[:invalid_price_lines, { list: name }]]
    end

    # A label, a price, a note if any, nothing else
    def valid_line?(line)
      note = line["note"]
      (line.keys - LINE_PARAMETERS).empty? && valid_label?(line["label"]) &&
        short_text?(line["price"], PRICE_MAX_LENGTH) && (note.nil? || short_text?(note, NOTE_MAX_LENGTH))
    end

    def short_text?(text, maximum)
      text.is_a?(String) && text.present? && text.length <= maximum
    end

    def duplicate_errors(lists)
      keys = lists.pluck("key").compact
      keys.select { |key| keys.count(key) > 1 }.uniq.map { |key| [:duplicate_price_list, { key: key }] }
    end
  end
end
