# The legal notice (legal_notices/_content), shown on its own page and in the settings
module LegalNoticesHelper
  CONTACT_EMAIL = "contact@fumblequest.com".freeze

  LEGAL_HEADING_CLASSES = {
    section: "text-lg font-bold text-ink",
    subsection: "text-base font-semibold text-ink"
  }.freeze

  # The page titles its sections in h2; the settings, where the section title is already an h2, in h3
  def legal_heading(text, level:, kind: :section)
    content_tag("h#{level}", text, class: LEGAL_HEADING_CLASSES.fetch(kind))
  end
end
