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
      # If the user typed a first message in the chat bar, send it right away
      # and generate the assistant's reply, so the chat opens already started.
      if first_message.present?
        @chat.messages.create!(role: "user", content: first_message)
        @chat.messages.create!(role: "assistant", content: ChatResponder.call(@chat))
      end
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

  def first_message
    @first_message ||= params[:message].to_s.strip
  end

  def chat_title
    return first_message.truncate(60) if first_message.present?
    params.dig(:chat, :title).presence || "Chat about my #{@trip.city} day"
  end
end
