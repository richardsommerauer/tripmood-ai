class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @chat = current_user.chats.find(params[:chat_id])
    @message = @chat.messages.new(message_params.merge(role: "user"))

    if @message.save
      # Generate the assistant's reply (AI or mock) and persist it.
      reply = ChatResponder.call(@chat)
      @assistant_message = @chat.messages.create!(role: "assistant", content: reply)
      respond_to do |format|
        format.turbo_stream # app/views/messages/create.turbo_stream.erb
        format.html { redirect_to @chat }
      end
    else
      respond_to do |format|
        # Drop the optimistic typing indicator; keep the user on the page.
        format.turbo_stream { render turbo_stream: turbo_stream.remove("typing"), status: :unprocessable_entity }
        format.html { redirect_to @chat, alert: @message.errors.full_messages.to_sentence.presence || "Please type a message or attach a file." }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:content, :file)
  end
end
