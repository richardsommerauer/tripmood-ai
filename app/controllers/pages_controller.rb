class PagesController < ApplicationController
  def home
    @recent_trips = Trip.order(created_at: :desc).limit(6)
  end
end
