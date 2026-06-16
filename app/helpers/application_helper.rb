module ApplicationHelper
  # True if an asset (e.g. "hero.png") exists in app/assets/images.
  # Lets the landing page use a real illustration when one is present,
  # and fall back to the built-in SVG scene otherwise.
  def asset_exists?(logical_path)
    Rails.application.assets&.find_asset(logical_path).present?
  rescue StandardError
    false
  end
end
