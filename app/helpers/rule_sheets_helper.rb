# The panel « Règles » of the game room (TemplateCopy#rule_sheets)
module RuleSheetsHelper
  # What the search reads: the title and the text, without accents nor capitals (as catalog_search_controller.js)
  def rule_entry_search_name(entry)
    I18n.transliterate("#{entry['title']} #{entry['text']}").downcase
  end
end
