module InvitationsHelper
  # The invitation page of a signed in user is as tall as the screen, like "My tables", beside their navigation
  # (above the floating bar of a phone, 5rem)
  def invitation_page_height_classes
    "min-h-[calc(100dvh-5rem)] md:min-h-dvh"
  end

  # "Invitation · from Luara", the gold line of the invitation cards, over the name of the table
  def invitation_eyebrow(game_table)
    label = tag.span(t("game_tables.invitation.label"), class: "text-brass")
    sender = t("game_tables.invitation.from", username: game_table.game_master&.username)
    safe_join([label, tag.span("· #{sender}", class: "text-muted")], " ")
  end
end
