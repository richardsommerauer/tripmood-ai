# TripPlanGenerator — owns the AI logic for building a day plan.
#
# .call(trip) returns a Hash (string keys, ready for jsonb) shaped like:
#   { "title", "summary", "stops" => [{ "name","duration","why" }],
#     "whyMood", "budgetTips"[], "transportTips"[], "safetyTips"[],
#     "relaxedAlternative", "reminder", "source" => "ai"|"mock" }
#
# Honesty rule: never invents exact prices or live opening hours.
class TripPlanGenerator
  REMINDER = "Please check current opening hours before you go.".freeze

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are TripMood AI, a friendly travel assistant.

    Your job is to create realistic mini travel plans for people who are in a
    city and have limited time.

    Always consider: city, available time, budget, mood, interests, energy level,
    realistic travel distances, breaks, food, safety, and not overloading the day.

    Return the answer in this structure:
    1. Short summary
    2. Recommended plan with 3 to 5 stops
    3. Why this matches the mood
    4. Budget tips
    5. Transport tips
    6. Optional relaxed alternative

    Do not invent exact prices or opening hours unless provided.
    If unsure, say 'please check current opening hours'.
    Keep the plan realistic, warm and human.
  PROMPT

  def self.call(trip)
    new(trip).call
  end

  def initialize(trip)
    @trip = trip
  end

  def call
    if AnthropicClient.available?
      begin
        return ai_plan.merge("reminder" => REMINDER, "source" => "ai")
      rescue => e
        Rails.logger.warn("[TripPlanGenerator] AI failed, using mock: #{e.message}")
      end
    end
    mock_plan.merge("source" => "mock")
  end

  private

  def ai_plan
    user_prompt = <<~MSG
      City: #{@trip.city}
      Available time: #{@trip.duration}
      Budget: #{@trip.budget}
      Mood: #{@trip.mood}
      Interests: #{@trip.interests_sentence}
      Energy level: #{@trip.energy}
      Travel style: #{@trip.travel_style}

      Return ONLY valid JSON with this exact shape:
      {
        "title": "short warm trip title",
        "summary": "1-2 sentence overview",
        "stops": [{ "name": "...", "duration": "e.g. 45 min", "why": "why it fits the mood" }],
        "whyMood": "short paragraph",
        "budgetTips": ["..."], "transportTips": ["..."], "safetyTips": ["..."],
        "relaxedAlternative": "one calmer variation"
      }
      Use 3 to 5 stops. Do not invent exact prices or opening hours.
      Respond with ONLY the JSON object — no prose, no markdown code fences.
    MSG

    raw = AnthropicClient.chat(
      system_prompt: SYSTEM_PROMPT,
      messages: [{ role: "user", content: user_prompt }],
      max_tokens: 2048
    )
    normalize(parse_json(raw))
  end

  # Claude is asked for raw JSON, but strip code fences / extra prose defensively.
  def parse_json(raw)
    text = raw.to_s.strip
    text = text.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "").strip
    if (open = text.index("{")) && (close = text.rindex("}"))
      text = text[open..close]
    end
    JSON.parse(text)
  end

  def normalize(h)
    {
      "title"   => h["title"].presence || "Your TripMood day",
      "summary" => h["summary"].to_s,
      "stops"   => Array(h["stops"]).first(5).map { |s|
        { "name" => s["name"].to_s, "duration" => s["duration"].to_s, "why" => s["why"].to_s }
      },
      "whyMood"            => h["whyMood"].to_s,
      "budgetTips"         => Array(h["budgetTips"]).compact,
      "transportTips"      => Array(h["transportTips"]).compact,
      "safetyTips"         => Array(h["safetyTips"]).compact,
      "relaxedAlternative" => h["relaxedAlternative"].to_s
    }
  end

  # ---- Mock fallback (always demo-ready) ----
  def mock_plan
    return bangalore_hero if hero_demo?

    likes_food    = @trip.interests.include?("food") || @trip.mood == "foodie"
    likes_culture = @trip.interests.include?("culture") || @trip.interests.include?("temples")
    city = @trip.city.presence || "your city"

    {
      "title"   => "A #{@trip.travel_style} #{@trip.duration} in #{city}",
      "summary" => "A realistic mini plan for #{@trip.duration} in #{city}, shaped around a \"#{@trip.mood}\" mood and a #{@trip.budget} budget.",
      "stops"   => [
        { "name" => (likes_food ? "A cozy local café to start" : "An easy, welcoming spot to start"),
          "duration" => "45 min",
          "why" => "A gentle opening that suits a \"#{@trip.mood}\" mood and a #{@trip.energy}-energy day." },
        { "name" => (likes_culture ? "A cultural highlight in #{city}" : "A signature local experience in #{city}"),
          "duration" => "60 min",
          "why" => "Chosen to match your interests (#{@trip.interests_sentence})." },
        { "name" => "A short local walk to see real neighborhood life",
          "duration" => "40 min",
          "why" => "Keeps a #{@trip.travel_style} pace and lets the city reveal itself naturally." },
        { "name" => (likes_food ? "A simple, authentic local meal" : "A relaxed food or drink break"),
          "duration" => "45 min",
          "why" => "Good food is the easiest way to feel a place — and a natural mid-day reset." }
      ],
      "whyMood"            => "This day is tuned to feel \"#{@trip.mood}\": the order, pace and breaks all respect your #{@trip.energy} energy and #{@trip.travel_style} style — discovery without overload.",
      "budgetTips"         => ["For a #{@trip.budget} budget, lean on local food, public spaces and free neighborhoods.", "Carry a little cash for small vendors. Prices may vary."],
      "transportTips"      => ["Keep your stops close together to avoid wasting time in traffic.", "Walking between nearby stops is often the fastest and most enjoyable option."],
      "safetyTips"         => ["Keep valuables secure and stay aware in crowded areas.", "Stay hydrated and pace yourself.", "Use this as a flexible plan, not a fixed booking."],
      "relaxedAlternative" => "Want it calmer? Keep just the first café, one main stop, and the food stop — and slow down at each.",
      "reminder"           => REMINDER
    }
  end

  def hero_demo?
    @trip.city.to_s.match?(/bangalore|bengaluru/i) &&
      @trip.mood == "tired but curious" && @trip.budget == "low"
  end

  def bangalore_hero
    {
      "title"   => "A Calm, Curious Afternoon in Bangalore",
      "summary" => "A gentle, low-cost loop for a tired-but-curious traveler: start slow with coffee, soak up a little culture, take an easy walk, and end with simple, satisfying local food.",
      "stops"   => [
        { "name" => "Start with a calm filter-coffee café", "duration" => "45 min",
          "why" => "Ease into the day without rushing. A quiet café matches a low-energy, curious mood and costs very little." },
        { "name" => "One cultural stop (a small museum or a historic temple)", "duration" => "60 min",
          "why" => "Just enough culture to feel curious and inspired, without a packed, tiring itinerary." },
        { "name" => "A short, shaded local walk (a park or a quiet street)", "duration" => "40 min",
          "why" => "Light movement keeps the day pleasant when your energy is low, and it's free." },
        { "name" => "Simple, tasty local food (a classic South Indian thali or street snack)", "duration" => "45 min",
          "why" => "Authentic flavor on a low budget — comforting and satisfying after a relaxed walk." },
        { "name" => "Optional: a relaxed bookshop or tea stop to wind down", "duration" => "30 min",
          "why" => "A soft ending that respects low energy while keeping the curious spark alive." }
      ],
      "whyMood"            => "Tired but curious means you want to discover something — without exhausting yourself. This plan keeps walking distances short, builds in breaks, and balances calm spots with small sparks of culture and flavor.",
      "budgetTips"         => ["Filter coffee, local thalis and street snacks are delicious and very affordable.", "Many parks, temples and neighborhoods are free to wander.", "Carry small cash for tiny shops and snacks. Prices may vary."],
      "transportTips"      => ["Auto-rickshaws and app cabs are easy for short hops; keep stops geographically close.", "Bangalore traffic can be slow — plan a small, compact loop instead of crossing the city.", "Walking between nearby stops is often faster (and nicer) than a short ride."],
      "safetyTips"         => ["Stay hydrated and take it slow in the afternoon heat.", "Keep your phone, cash and bag secure in busy markets.", "Use this as a flexible plan, not a fixed booking."],
      "relaxedAlternative" => "Even slower? Keep just the café, one cultural stop and the food stop — and spend longer at each.",
      "reminder"           => REMINDER
    }
  end
end
