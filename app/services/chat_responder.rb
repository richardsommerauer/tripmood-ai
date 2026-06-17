# ChatResponder — generates the assistant's reply within a trip chat.
#
# .call(chat) reads the trip context + conversation history (including any
# file attachment on the latest user message) and returns reply text.
# Falls back to a helpful mock when no API key is configured.
class ChatResponder
  SYSTEM_PROMPT = <<~PROMPT.freeze
    # Persona
    You are TripMood AI, a friendly and practical travel planning assistant.

    # Context
    You are helping the user with ONE specific trip / day plan. Use the selected
    trip data as your context: city, mood, duration, budget, style, the existing
    plan and its stops, plus any budget, transport and safety tips. The full trip
    context is provided below this prompt.

    # Task
    Help the user improve, understand, customize, or troubleshoot this trip. For
    example: make the plan cheaper, more relaxed, or more adventurous; suggest food
    stops or transport improvements; explain why the plan works; or adapt it for
    families, couples, solo travelers, or rainy weather.

    # Rules
    - Stay focused on the selected trip.
    - Be practical and concrete.
    - Do not invent exact opening hours, live prices, or live availability.
    - When relevant, remind the user that opening hours, prices and safety
      conditions can change ("please check current opening hours", "prices may vary").
    - Ask a helpful follow-up question only when it's genuinely needed.
    - Keep the tone warm, clear, and beginner-friendly.
    - Treat the plan as flexible, not a fixed booking.
    - Answer in clear Markdown.
  PROMPT

  def self.call(chat)
    new(chat).call
  end

  def initialize(chat)
    @chat = chat
    @trip = chat.trip
  end

  def call
    if AnthropicClient.available?
      begin
        return AnthropicClient.chat(
          system_prompt: "#{SYSTEM_PROMPT}\n\n#{trip_context}",
          messages: conversation_messages,
          max_tokens: 1024
        ).strip
      rescue => e
        Rails.logger.warn("[ChatResponder] AI failed, using mock: #{e.message}")
      end
    end
    mock_reply
  end

  private

  # Just the user/assistant turns — the system prompt is passed separately.
  def conversation_messages
    @chat.messages.ordered.map do |m|
      content = m.content.to_s
      content += "\n[The user attached a file: #{m.file.filename}]" if m.file.attached?
      { role: m.role, content: content }
    end
  end

  def trip_context
    stops = @trip.stops.map { |s| "- #{s['name']} (#{s['duration']}) — #{s['why']}" }.join("\n")
    <<~CTX
      ## Selected trip context
      Here is the plan you built for this trip:
      City: #{@trip.city} | Time: #{@trip.duration} | Budget: #{@trip.budget}
      Mood: #{@trip.mood} | Energy: #{@trip.energy} | Style: #{@trip.travel_style}
      Interests: #{@trip.interests_sentence}
      Title: #{@trip.title}
      Summary: #{@trip.summary}

      Stops:
      #{stops}

      Why it matches the mood: #{@trip.why_mood}
      Budget tips: #{tip_list(@trip.budget_tips)}
      Transport tips: #{tip_list(@trip.transport_tips)}
      Safety note: #{tip_list(@trip.safety_tips)}
      Relaxed alternative: #{@trip.relaxed_alt}
    CTX
  end

  # Render a list of tips inline; fall back to a dash when empty.
  def tip_list(tips)
    list = Array(tips).reject(&:blank?)
    list.any? ? list.join("; ") : "—"
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
