module AuthCardsHelper
  # The block is captured here, while the page is still the current template, so that the short
  # translation keys inside it (t(".title")) are looked up for the page and not for the card partial
  def auth_card(title:, subtitle: nil, &)
    render "shared/auth_card", title: title, subtitle: subtitle, content: capture(&)
  end

  # The messages sit above the title of the visitor pages: without this space, they touched it
  def auth_messages_classes
    visible_messages? ? "mb-6" : ""
  end
end
