# The last step of the creation of a table: the summary, with the invitation link.
# The first step and the band of the steps: GameTableCreationHelper
module GameTableLastStepsHelper
  # The invitation link sits in a read-only field, styled like the other fields (written once, in Simple Form)
  def field_label_classes
    SimpleFormFieldClasses::LABEL
  end

  def read_only_field_classes
    "#{SimpleFormFieldClasses::INPUT} truncate"
  end

  def field_hint_classes
    SimpleFormFieldClasses::HINT
  end

  def summary_description(game_table)
    game_table.description.presence || t("game_tables.summaries.show.no_description")
  end

  def summary_sheet_template_name(game_table)
    game_table.sheet_template&.name
  end

  # The form that invites a player by username asks the server for suggestions while typing
  def username_suggestions_data(game_table)
    { controller: "username-suggestions",
      username_suggestions_url_value: game_table_player_suggestions_path(game_table) }
  end

  # autocomplete off: the browser's own memory of typed values would mix with the suggestions of the app
  def username_suggestions_input_options
    { autocomplete: "off", list: "player-suggestions",
      data: { username_suggestions_target: "input", action: "input->username-suggestions#suggest" } }
  end

  # An invited player: "Pending" until they accept, then "Player" (same badge as on the table cards)
  def invitation_status_badge_classes(participation)
    badge_classes(participation.pending? ? :pending : :player)
  end

  def invitation_status_label(participation)
    t("game_tables.summaries.invitation.statuses.#{participation.status}")
  end
end
