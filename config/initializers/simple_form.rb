# frozen_string_literal: true
#
# Uncomment this and change the path if necessary to include your own
# components.
# See https://github.com/heartcombo/simple_form#custom-components to know
# more about custom components.
# Dir[Rails.root.join('lib/components/**/*.rb')].each { |f| require f }
#
# Field styles, written once for every form of the app. Classes are written in full for Tailwind.
module SimpleFormFieldClasses
  LABEL = "mb-1.5 block text-[13px] font-semibold text-ink"

  # Focus: the border takes focus-ring, with a soft 3 px halo (outline-hidden keeps an outline
  # in Windows high contrast mode). Errors follow aria-invalid, which Simple Form sets on invalid
  # inputs: a 1 px border was too thin to notice, so a ring doubles it and the background turns pink.
  # aria-invalid variants come after focus and hover in the CSS, so the red always wins.
  INPUT = %w[
    block h-11 w-full rounded-lg border border-field-line bg-field px-3.5 text-sm text-ink
    placeholder:text-muted hover:border-muted
    focus:border-focus-ring focus:ring-3 focus:ring-focus-ring/30 focus:outline-hidden
    aria-invalid:border-error-ink aria-invalid:bg-error-bg aria-invalid:ring-1 aria-invalid:ring-error-ink
    aria-invalid:hover:border-error-ink aria-invalid:focus:ring-3 aria-invalid:focus:ring-error-ink/30
    disabled:cursor-not-allowed disabled:opacity-50
  ].join(" ").freeze

  HINT = "mt-1.5 text-xs text-muted"
  ERROR = "mt-1.5 text-xs text-error-ink"

  # Drawn by us (appearance-none): the native check box cannot be reshaped, only recolored
  CHECKBOX = %w[
    size-4.5 shrink-0 cursor-pointer appearance-none rounded-[3px] border border-field-line bg-field
    checked:border-primary checked:bg-primary checked:bg-checkmark
    focus-visible:border-focus-ring focus-visible:ring-3 focus-visible:ring-focus-ring/30 focus-visible:outline-hidden
  ].join(" ").freeze

  CHECKBOX_LABEL = "cursor-pointer text-sm text-ink"
end

# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  # Wrappers are used by the form builder to generate a
  # complete input. You can remove any component from the
  # wrapper, change the order or even add your own to the
  # stack. The options given below are used to wrap the
  # whole input.
  config.wrappers :default, class: "mb-4" do |b|
    ## Extensions enabled by default
    # Any of these extensions can be disabled for a
    # given input by passing: `f.input EXTENSION_NAME => false`.
    # You can make any of these extensions optional by
    # renaming `b.use` to `b.optional`.

    # Determines whether to use HTML5 (:email, :url, ...)
    # and required attributes
    b.use :html5

    # Calculates placeholders automatically from I18n
    # You can also pass a string as f.input placeholder: "Placeholder"
    b.use :placeholder

    ## Optional extensions
    # They are disabled unless you pass `f.input EXTENSION_NAME => true`
    # to the input. If so, they will retrieve the values from the model
    # if any exists. If you want to enable any of those
    # extensions by default, you can change `b.optional` to `b.use`.

    # Calculates maxlength from length validations for string inputs
    # and/or database column lengths
    b.optional :maxlength

    # Calculate minlength from length validations for string inputs
    b.optional :minlength

    # Calculates pattern from format validations for string inputs
    b.optional :pattern

    # Calculates min and max from length validations for numeric inputs
    b.optional :min_max

    # Calculates readonly automatically from readonly attributes
    b.optional :readonly

    ## Inputs
    b.use :label, class: SimpleFormFieldClasses::LABEL
    b.use :input, class: SimpleFormFieldClasses::INPUT
    b.use :hint, wrap_with: { tag: :p, class: SimpleFormFieldClasses::HINT }
    b.use :error, wrap_with: { tag: :p, class: SimpleFormFieldClasses::ERROR }
  end

  # Check boxes: the box and its label side by side (inline style), so each one gets its own classes
  config.wrappers :boolean, class: "mb-4" do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper tag: :div, class: "flex items-center gap-2" do |box_and_label|
      box_and_label.use :input, class: SimpleFormFieldClasses::CHECKBOX
      box_and_label.use :label, class: SimpleFormFieldClasses::CHECKBOX_LABEL
    end
    b.use :hint, wrap_with: { tag: :p, class: SimpleFormFieldClasses::HINT }
    b.use :error, wrap_with: { tag: :p, class: SimpleFormFieldClasses::ERROR }
  end

  # The default wrapper to be used by the FormBuilder.
  config.default_wrapper = :default

  # Define the way to render check boxes / radio buttons with labels.
  #   inline: input + label
  #   nested: label > input
  # Inline: with nested, only the label_input component writes the label text, and the box
  # and its text could not get separate classes
  config.boolean_style = :inline

  # No default class for buttons: each button gets button_classes(...) in its view ("btn" came from Bootstrap)
  config.button_class = nil

  # Method used to tidy up errors. Specify any Rails Array method.
  # :first lists the first message for each field.
  # Use :to_sentence to list all errors for each field.
  # config.error_method = :first

  # Default tag used for error notification helper.
  config.error_notification_tag = :div

  # CSS class to add for error notification helper.
  config.error_notification_class = 'error_notification'

  # Series of attempts to detect a default label method for collection.
  # config.collection_label_methods = [ :to_label, :name, :title, :to_s ]

  # Series of attempts to detect a default value method for collection.
  # config.collection_value_methods = [ :id, :to_s ]

  # You can wrap a collection of radio/check boxes in a pre-defined tag, defaulting to none.
  # config.collection_wrapper_tag = nil

  # You can define the class to use on all collection wrappers. Defaulting to none.
  # config.collection_wrapper_class = nil

  # You can wrap each item in a collection of radio/check boxes with a tag,
  # defaulting to :span.
  # config.item_wrapper_tag = :span

  # You can define a class to use in all item wrappers. Defaulting to none.
  # config.item_wrapper_class = nil

  # How the label text should be generated altogether with the required text.
  # config.label_text = lambda { |label, required, explicit_label| "#{required} #{label}" }

  # You can define the class to use on all labels. Default is nil.
  # config.label_class = nil

  # You can define the default class to be used on forms. Can be overridden
  # with `html: { :class }`. Defaulting to none.
  # config.default_form_class = nil

  # You can define which elements should obtain additional classes
  # config.generate_additional_classes_for = [:wrapper, :label, :input]

  # Whether attributes are required by default (or not). Default is true.
  # config.required_by_default = true

  # Tell browsers whether to use the native HTML5 validations (novalidate form option).
  # These validations are enabled in SimpleForm's internal config but disabled by default
  # in this configuration, which is recommended due to some quirks from different browsers.
  # To stop SimpleForm from generating the novalidate option, enabling the HTML5 validations,
  # change this configuration to true.
  config.browser_validations = false

  # Custom mappings for input types. This should be a hash containing a regexp
  # to match as key, and the input type that will be used when the field name
  # matches the regexp as value.
  # config.input_mappings = { /count/ => :integer }

  # Custom wrappers for input types. This should be a hash containing an input
  # type as key and the wrapper that will be used for all inputs with specified type.
  config.wrapper_mappings = { boolean: :boolean }

  # Namespaces where SimpleForm should look for custom input classes that
  # override default inputs.
  # config.custom_inputs_namespaces << "CustomInputs"

  # Default priority for time_zone inputs.
  # config.time_zone_priority = nil

  # Default priority for country inputs.
  # config.country_priority = nil

  # When false, do not use translations for labels.
  # config.translate_labels = true

  # Automatically discover new inputs in Rails' autoload path.
  # config.inputs_discovery = true

  # Cache SimpleForm inputs discovery
  # config.cache_discovery = !Rails.env.development?

  # Default class for inputs
  # config.input_class = nil

  # Define the default class of the input wrapper of the boolean input.
  # Only used with boolean_style = :nested: our check boxes use the :boolean wrapper instead
  # config.boolean_label_class = nil

  # Defines if the default input wrapper class should be included in radio
  # collection wrappers.
  # config.include_default_input_wrapper_class = true

  # Defines which i18n scope will be used in Simple Form.
  # config.i18n_scope = 'simple_form'

  # Defines validation classes to the input_field. By default it's nil.
  # config.input_field_valid_class = 'is-valid'
  # config.input_field_error_class = 'is-invalid'
end
