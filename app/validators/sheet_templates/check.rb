module SheetTemplates
  # What the checks of a template share: its parts of fields, and the names said in the messages (the part, the field)
  class Check
    PARTS = %w[character_fields npc_fields item_fields spell_fields].freeze
    # A key is the name of the field inside the app (a form field, an id of the page, a key of the database, a part of
    # an address for a step): lower case letters, digits and _, a letter first (snake_case). The template editor will
    # make it from the label ("Points de vie" gives points_de_vie)
    KEY_FORMAT = /\A[a-z][a-z0-9_]*\z/
    # A label is free text, written in the words of the game and always escaped on the page (never html_safe): only
    # its length and the characters that would break a line or hide in it (control characters) are refused
    LABEL_MAX_LENGTH = 60
    CONTROL_CHARACTERS = /[[:cntrl:]]/

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

    def valid_key?(key)
      key.is_a?(String) && key.match?(KEY_FORMAT)
    end

    def valid_label?(label)
      label.is_a?(String) && label.strip.present? && label.length <= LABEL_MAX_LENGTH &&
        !label.match?(CONTROL_CHARACTERS)
    end

    def keys_of_type(fields, type)
      fields.select { |field| field["type"] == type }.pluck("key")
    end

    def type_name(type)
      I18n.t("sheet_templates.validator.field_types.#{type}")
    end
  end
end
