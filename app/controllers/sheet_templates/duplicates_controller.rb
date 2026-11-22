module SheetTemplates
  # "Duplicate": a template of the game master made from one they may pick (a predefined template in the language of
  # the page, or one of their own; 404 for the template of another game master), then its page, to rename it
  class DuplicatesController < ApplicationController
    def create
      original = SheetTemplate.available_to(current_user).find(params[:sheet_template_id])
      copy = SheetTemplates::Duplicator.new(original: original, owner: current_user).call
      # The page of the copy shows its name: the message is for screen readers only
      redirect_to copy, flash: { screen_reader_notice: t(".created", name: copy.name) }
    end
  end
end
