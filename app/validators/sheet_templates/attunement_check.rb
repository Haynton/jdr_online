module SheetTemplates
  # How many magic items a character may be attuned to at a time (character_fields.attunement: limit), when the template
  # says it (Attunable): a whole number from 1
  class AttunementCheck < Check
    def call
      attunement = @sheet_template.character_fields.to_h["attunement"]
      return [] if attunement.nil?
      return [] if attunement.is_a?(Hash) && attunement.keys == ["limit"] && attunement["limit"].is_a?(Integer) &&
                   attunement["limit"].positive?

      [[:invalid_attunement, {}]]
    end
  end
end
