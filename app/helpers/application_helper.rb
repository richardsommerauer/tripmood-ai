module ApplicationHelper
  # True if an asset (e.g. "hero.png") exists in app/assets/images.
  # Lets the landing page use a real illustration when one is present,
  # and fall back to the built-in SVG scene otherwise.
  def asset_exists?(logical_path)
    Rails.application.assets&.find_asset(logical_path).present?
  rescue StandardError
    false
  end

  # Render the assistant's Markdown reply as safe HTML.
  # filter_html strips any raw HTML in the model output; links open in a new tab.
  MARKDOWN_RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true, link_attributes: { target: "_blank", rel: "noopener" }),
    autolink: true, fenced_code_blocks: true, tables: true, strikethrough: true, no_intra_emphasis: true
  )

  def markdown(text)
    sanitize(MARKDOWN_RENDERER.render(text.to_s))
  end
end
