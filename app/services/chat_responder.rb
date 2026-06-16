# ChatResponder — generates the assistant's reply within a trip chat.
#
# .call(chat) reads the trip context + conversation history (including any
# file attachment on the latest user message) and returns reply text.
# Falls back to a helpful mock when no API key is configured.
class ChatResponder
  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are TripMood AI, a warm, honest travel assistant chatting with a traveler
    about a specific day plan you already built for them. Help them refine it,
    answer questions, and suggest tweaks (cheaper, more relaxed, more food,
    hidden gems, swaps). Keep replies concise and practical.

    Never invent exact prices or live opening hours. Say "please check current
    opening hours" and "prices may vary" when relevant. Treat the plan as
    flexible, not a fixed booking.
  PROMPT

  def self.call(chat)
    new(chat).call
  end

  def initialize(chat)
    @chat = chat
    @trip = chat.trip
  end

  def call
    if OpenaiClient.available?
      begin
        return OpenaiClient.chat(messages, temperature: 0.7).strip
      rescue => e
        Rails.logger.warn("[ChatResponder] AI failed, using mock: #{e.message}")
      end
    end
    mock_reply
  end

  private

  def messages
    msgs = [{ role: "system", content: SYSTEM_PROMPT }, { role: "system", content: trip_context }]
    @chat.messages.ordered.each do |m|
      content = m.content.to_s
      content += "\n[The user attached a file: #{m.file.filename}]" if m.file.attached?
      msgs << { role: m.role, content: content }
    end
    msgs
  end

  def trip_context
    stops = @trip.stops.map { |s| "- #{s['name']} (#{s['duration']})" }.join("\n")
    <<~CTX
      Here is the plan you built:
      City: #{@trip.city} | Time: #{@trip.duration} | Budget: #{@trip.budget}
      Mood: #{@trip.mood} | Energy: #{@trip.energy} | Style: #{@trip.travel_style}
      Title: #{@trip.title}
      Stops:
      #{stops}
    CTX
  end

  # Mock reply: acknowledge the latest message + attachment, stay in character.
  def mock_reply
    last = @chat.messages.ordered.last
    text = last&.content.to_s.downcase
    attach = last&.file&.attached? ? " I can see you attached #{last.file.filename} — in the live version I'd read it to tailor the plan." : ""

    suggestion =
      if text.include?("cheap") || text.include?("budget")
        "To keep it cheaper: stick to local thalis and street snacks, lean on free parks and neighborhoods, and walk between nearby stops instead of taking cabs."
      elsif text.include?("relax") || text.include?("slow") || text.include?("tired")
        "To slow it down: drop one stop and spend longer at the café and the food stop. Less moving, more sitting and watching the city."
      elsif text.include?("food") || text.include?("eat")
        "For more food: add a second snack stop near your walk — something simple and local. Prices may vary, and please check current opening hours."
      elsif text.include?("hidden") || text.include?("gem") || text.include?("local")
        "For hidden gems: swap the main cultural stop for a smaller neighborhood spot locals love — quieter, more memorable, still close by."
      else
        "Happy to adjust the plan — want it cheaper, more relaxed, more food, or with a few hidden gems? Tell me what matters most today."
      end

    "Thanks!#{attach} #{suggestion} Remember to treat this as a flexible plan, not a fixed booking."
  end
end
