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

  def summary_description(game_table)
    game_table.description.presence || t("game_tables.summaries.show.no_description")
  end

  def summary_sheet_template_name(game_table)
    game_table.sheet_template&.name
  end

  # The game master first, then every invited player in the order they were invited
  def table_participants(game_table)
    game_table.participations.select(&:game_master?) + game_table.player_participations
  end

  # Same badges as on the table cards: "GM", then "Player" for an invited player once they accept, "Pending" before
  def participant_badge_classes(participation)
    badge_classes(participant_badge(participation))
  end

  def participant_badge_label(participation)
    t("game_tables.summaries.participants.badges.#{participant_badge(participation)}")
  end

  private

  def participant_badge(participation)
    return :game_master if participation.game_master?

    participation.pending? ? :pending : :player
  end
end
