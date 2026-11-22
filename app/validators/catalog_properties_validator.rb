# Checks the properties of a catalog entry against the fields its template declares for its kind (spell_fields for a
# spell), with the same rules as a character sheet (FieldValueChecker): JSONB has no check of its own in the database.
# An error goes on "properties.<key of the field>". A field marked required must be there; a key the template does not
# declare is refused. Kinds the template does not describe yet (items, NPCs: later) are not checked
class CatalogPropertiesValidator < ActiveModel::Validator
  def validate(entry)
    fields = entry.property_fields
    return if fields.nil?

    fields_by_key = fields.index_by { |field| field["key"] }
    entry.properties.each do |key, value|
      error_type, error_options = FieldValueChecker.error_for(fields_by_key[key], value)
      entry.errors.add(:"properties.#{key}", error_type, **error_options.to_h) if error_type
    end
    validate_required_fields(entry, fields)
  end

  private

  def validate_required_fields(entry, fields)
    fields.select { |field| field["required"] }.each do |field|
      entry.errors.add(:"properties.#{field['key']}", :blank) if entry.properties[field["key"]].nil?
    end
  end
end
