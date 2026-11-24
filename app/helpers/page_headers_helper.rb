module PageHeadersHelper
  # Title of a page of the app, with an optional subtitle and, in the block, the buttons shown on its right.
  # The block is captured here, while the page is still the current template, so that the short
  # translation keys inside it (t(".create_table")) are looked up for the page and not for the partial
  def page_header(title:, subtitle: nil, &)
    actions = capture(&) if block_given?
    render "shared/page_header", title: title, subtitle: subtitle, actions: actions
  end

  # A subtitle in several lines, one sentence each (an introduction that says what is done already, then what the
  # page is for): each text is escaped, a line break between them
  def subtitle_lines(*texts)
    safe_join(texts, tag.br)
  end
end
