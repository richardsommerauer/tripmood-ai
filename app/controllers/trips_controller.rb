class TripsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_trip, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:edit, :update, :destroy]

  # Public gallery of day plans
  def index
    @trips = Trip.order(created_at: :desc)
  end

  def show
    @chats = current_user ? @trip.chats.where(user: current_user).order(created_at: :desc) : []
  end

  def new
    @trip = current_user.trips.new
  end

  def create
    @trip = current_user.trips.new(trip_params)
    @trip.plan = TripPlanGenerator.call(@trip) if @trip.valid?
    if @trip.valid?
      @trip.title   = @trip.plan["title"]
      @trip.summary = @trip.plan["summary"]
      @trip.save!
      redirect_to @trip, notice: "Your day is ready ✨"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @trip.update(trip_params)
      # Regenerate the plan from the new inputs
      @trip.plan = TripPlanGenerator.call(@trip)
      @trip.update!(title: @trip.plan["title"], summary: @trip.plan["summary"])
      redirect_to @trip, notice: "Plan updated and regenerated ✨"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip.destroy
    redirect_to trips_path, notice: "Trip deleted.", status: :see_other
  end

  private

  def set_trip
    @trip = Trip.find(params[:id])
  end

  def authorize_owner!
    redirect_to trips_path, alert: "That's not your trip." unless @trip.user == current_user
  end

  def trip_params
    params.require(:trip).permit(:city, :duration, :budget, :mood, :energy, :travel_style, interests: [])
  end
end
