module AuthCardsHelper
  # The block is captured here, while the page is still the current template, so that the short
  # translation keys inside it (t(".title")) are looked up for the page and not for the card partial
  # eyebrow: a short line over the title, in small capitals ("Invitation · from Luara")
  def auth_card(title:, subtitle: nil, eyebrow: nil, &)
    render "shared/auth_card", title: title, subtitle: subtitle, eyebrow: eyebrow, content: capture(&)
  end
end
