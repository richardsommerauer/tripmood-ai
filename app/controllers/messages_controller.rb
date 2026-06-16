class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = @chat.messages.new(message_params.merge(role: "user"))

    if @message.save
      # Generate the assistant's reply (AI or mock) and persist it.
      reply = ChatResponder.call(@chat)
      @chat.messages.create!(role: "assistant", content: reply)
      redirect_to @chat
    else
      redirect_to @chat, alert: "Please type a message or attach a file."
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :file)
  end
end
