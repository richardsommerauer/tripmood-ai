class ChatsController < ApplicationController
  before_action :authenticate_user!

  def index
    @trip = Trip.find(params[:trip_id])
    @chats = @trip.chats.where(user: current_user).order(created_at: :desc)
  end

  def create
    @trip = Trip.find(params[:trip_id])
    @chat = @trip.chats.new(user: current_user, title: chat_title)
    if @chat.save
      redirect_to @chat
    else
      redirect_to @trip, alert: "Could not start the chat."
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @trip = @chat.trip
    @message = Message.new
  end

  def destroy
    @chat = current_user.chats.find(params[:id])
    trip = @chat.trip
    @chat.destroy
    redirect_to trip, notice: "Chat deleted.", status: :see_other
  end

  private

  def chat_title
    params.dig(:chat, :title).presence || "Chat about my #{Trip.find(params[:trip_id]).city} day"
  end
end
