# The form of a field in the template editor (sheet_templates/fields/edit): each setting drawn by its kind of input
# (FieldParameters), with Simple Form, so that it looks like every other field of the app. The value shown is the one
# the game master just typed when the template refused it, otherwise the one saved
module SheetTemplates
  module FieldFormHelper
    SCOPE = "sheet_templates.parameters".freeze
    # A field of the list of the editor: a light line that opens its form as a whole, gold outline on hover
    FIELD_LINE_CLASSES = %w[
      flex items-center justify-between gap-3 rounded-lg bg-surface px-4 py-3 ring-1 ring-line transition-shadow
      hover:ring-2 hover:ring-brass
      focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-focus-ring
    ].join(" ").freeze
    # The options of the input of each kind (a method per kind: one place to change how a kind is asked)
    INPUT_OPTIONS = {
      text: :text_input_options, long_text: :long_text_input_options, integer: :integer_input_options,
      decimal: :decimal_input_options, lines: :lines_input_options, boolean: :boolean_input_options,
      asked_at_creation: :asked_at_creation_input_options, choice: :choice_input_options,
      reference: :reference_input_options, section: :section_input_options
    }.freeze

    # The settings of the field, the common ones then those of its type, without the fixed ones
    def field_parameter_groups(field)
      editable = SheetTemplates::FieldUpdater.editable_parameters(field)
      common, own = editable.partition { |parameter| FieldTypes::Base::COMMON_PARAMETERS.include?(parameter) }
      { general: common, type: own }.reject { |_group, parameters| parameters.empty? }
    end

    # The input of one setting, labelled and explained in the words of the app. Its help is the note of the button (i)
    # beside its label (help_id, info_notes_controller.js), and describes the input
    def field_parameter_input(form, parameter, context, help_id:)
      kind = FieldParameters.kind(parameter, FieldTypes.of(context[:field]))
      value = context[:submitted].key?(parameter) ? context[:submitted][parameter] : context[:field][parameter]
      options = public_send(INPUT_OPTIONS.fetch(kind), parameter, value, context)
      options[:input_html] = options.fetch(:input_html, {}).merge(aria: { describedby: help_id })
      form.input parameter, **options, label: t("#{SCOPE}.#{parameter}.label"), hint: t("#{SCOPE}.#{parameter}.hint"),
                                       hint_html: { id: help_id, data: { info_notes_target: "note" } },
                                       required: parameter_required?(parameter, context[:field])
    end

    def text_input_options(_parameter, value, _context)
      { as: :string, input_html: { value: value, autocomplete: "off" } }
    end

    def long_text_input_options(_parameter, value, _context)
      { as: :text, input_html: { value: value } }
    end

    def integer_input_options(_parameter, value, _context)
      { as: :integer, input_html: { value: value } }
    end

    # A decimal with a comma or a point (0,5)
    def decimal_input_options(_parameter, value, _context)
      { as: :string, input_html: { value: value, inputmode: "decimal", autocomplete: "off" } }
    end

    # One option per line
    def lines_input_options(_parameter, value, _context)
      { as: :text, input_html: { value: value.is_a?(Array) ? value.join("\n") : value } }
    end

    def boolean_input_options(_parameter, value, _context)
      { as: :boolean, input_html: { checked: [true, "1"].include?(value) } }
    end

    # Ticked unless the field says false
    def asked_at_creation_input_options(_parameter, value, _context)
      { as: :boolean, input_html: { checked: ![false, "0"].include?(value) } }
    end

    # A closed list, each value named in the words of the app
    def choice_input_options(parameter, value, _context)
      choices = FieldParameters.choices(parameter).map do |choice|
        [t("#{SCOPE}.#{parameter}.values.#{choice}"), choice]
      end
      { collection: choices, selected: value, include_blank: t("#{SCOPE}.none") }
    end

    # The fields of the type the setting expects, by their label (the key stays inside the app)
    def reference_input_options(parameter, value, context)
      expected_type = FieldTypes.of(context[:field]).references.fetch(parameter)
      candidates = context[:fields].select { |field| field["type"] == expected_type && field != context[:field] }
      { collection: candidates.map { |field| [field["label"], field["key"]] },
        selected: value, include_blank: t("#{SCOPE}.none") }
    end

    # The sections of the sheet, in their order
    def section_input_options(_parameter, value, context)
      { collection: context[:fields].pluck("section").uniq, selected: value, include_blank: false }
    end

    def field_type_name(field)
      t("sheet_templates.validator.field_types.#{field['type']}")
    end

    private

    # The settings without which the field is refused: its label, those its type needs. The section always has a value
    # (a list without an empty option): no asterisk, and Rails refuses a required select without an empty option
    def parameter_required?(parameter, field)
      parameter == "label" || FieldTypes.of(field).required_parameters.include?(parameter)
    end
  end
end
