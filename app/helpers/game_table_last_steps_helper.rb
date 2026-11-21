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

  # An invited player: "Pending" until they accept, then "Player" (same badge as on the table cards)
  def invitation_status_badge_classes(participation)
    badge_classes(participation.pending? ? :pending : :player)
  end

  def invitation_status_label(participation)
    t("game_tables.summaries.invitation.statuses.#{participation.status}")
  end
end
