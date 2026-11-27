module SheetTemplates
  # The rule sheets of the template (character_fields.rule_sheets, decision of 27 November): short rules the game master
  # reads in the game room (travel, environment, fear, traps...), written in the words of the game. A list where each
  # sheet has a key (unique), a label and its entries, each entry a title and a text of 800 characters at most
  class RuleSheetsCheck < Check
    PARAMETERS = %w[key label entries].freeze
    ENTRY_PARAMETERS = %w[title text].freeze
    TEXT_MAX_LENGTH = 800

    def call
      sheets = @sheet_template.character_fields.to_h["rule_sheets"]
      return [] if sheets.nil?
      return [[:invalid_rule_sheets, {}]] unless sheets.is_a?(Array) && sheets.all?(Hash)

      sheets.flat_map { |sheet| sheet_errors(sheet) } + duplicate_errors(sheets)
    end

    private

    def sheet_errors(sheet)
      name = sheet["label"].presence || sheet["key"].to_s
      unknown = (sheet.keys - PARAMETERS).map do |parameter|
        [:unknown_rule_sheet_parameter, { sheet: name, parameter: parameter }]
      end
      unknown + key_and_label_errors(sheet) + entries_errors(sheet["entries"], name)
    end

    def key_and_label_errors(sheet)
      key = sheet["key"].to_s
      errors = valid_key?(sheet["key"]) ? [] : [[:invalid_rule_sheet_key, { key: key }]]
      return errors if valid_label?(sheet["label"])

      errors + [[:invalid_rule_sheet_label, { key: key, count: LABEL_MAX_LENGTH }]]
    end

    def entries_errors(entries, name)
      valid = entries.is_a?(Array) && entries.any? && entries.all? { |entry| entry.is_a?(Hash) && valid_entry?(entry) }
      valid ? [] : [[:invalid_rule_sheet_entries, { sheet: name, count: TEXT_MAX_LENGTH }]]
    end

    def valid_entry?(entry)
      text = entry["text"]
      (entry.keys - ENTRY_PARAMETERS).empty? && valid_label?(entry["title"]) && text.is_a?(String) &&
        text.strip.present? && text.length <= TEXT_MAX_LENGTH
    end

    def duplicate_errors(sheets)
      keys = sheets.pluck("key").compact
      keys.select { |key| keys.count(key) > 1 }.uniq.map { |key| [:duplicate_rule_sheet, { key: key }] }
    end
  end
end
