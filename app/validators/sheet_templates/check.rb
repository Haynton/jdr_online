module SheetTemplates
  # What the checks of a template share: its parts of fields, and the names said in the messages (the part, the field)
  class Check
    PARTS = %w[character_fields npc_fields item_fields spell_fields].freeze

    def initialize(sheet_template)
      @sheet_template = sheet_template
    end

    private

    def fields_of(part)
      @sheet_template.public_send(part).to_h["fields"].to_a
    end

    def character_fields
      fields_of("character_fields")
    end

    # "Fiche du personnage › Points de vie": where the error is, as the game master reads it
    def context(part, field = nil)
      { part: I18n.t("sheet_templates.validator.parts.#{part}"), field: field && (field["label"] || field["key"]) }
    end

    def keys_of_type(fields, type)
      fields.select { |field| field["type"] == type }.pluck("key")
    end

    def type_name(type)
      I18n.t("sheet_templates.validator.field_types.#{type}")
    end
  end
end
