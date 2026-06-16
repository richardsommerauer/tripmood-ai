class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, etc.
  allow_browser versions: :modern
end
