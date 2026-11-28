# Whether a field is shown, for the values of an entry: a field that says shown_with (the damage of an item, for a
# weapon only) shows while the list it names holds one of its values; another field always shows. Read by the window
# of a catalog entry, whose twin in the page (shown_with_controller.js) does the same while the list changes
module FieldShownWith
  def self.shown?(field, values)
    condition = field["shown_with"]
    return true unless condition

    condition["values"].include?(values.to_h[condition["field"]])
  end
end
