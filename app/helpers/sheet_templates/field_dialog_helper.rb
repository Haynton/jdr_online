# The form of a field in a window over the creation path, like the settings window (decision: a page of its own left
# a large empty room beside the form; a panel on the right was tried and refused). A field of the path loads its form
# into the frame of the window (sheet_templates/fields/_dialog), which frame_dialog_controller.js opens once it has
# arrived. Opened directly, or
# without JavaScript, the address of the form stays a whole page
module SheetTemplates
  module FieldDialogHelper
    FRAME = "field_dialog".freeze

    # The link of a field: into the window, never prefetched (an answer laid out for the window must not be reused for
    # the whole page, as happened with the settings window)
    def field_dialog_link_data
      { turbo_frame: FRAME, turbo_prefetch: false }
    end

    # The request asks for the form in the window, not for the whole page
    def field_in_dialog?
      turbo_frame_request_id == FRAME
    end
  end
end
