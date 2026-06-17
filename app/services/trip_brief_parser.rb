# TripBriefParser — turns a free-text "describe your day" brief into structured
# Trip attributes (city, duration, budget, mood, energy, travel_style, interests).
#
# Uses Claude to extract a small JSON object, then sanitises every field against
# the Trip enums so we never persist an invalid value. Falls back to safe
# defaults if no API key is set or parsing fails — the caller validates the Trip
# and sends the user to the guided form when something essential (city) is missing.
class TripBriefParser
  MAX_BRIEF = 500

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You convert a traveler's free-text description of the day they want into
    structured trip parameters. Respond with ONLY a JSON object, no prose, with
    these keys: "city" (string), "duration", "budget", "mood", "energy",
    "travel_style", "interests" (array of strings).

    Pick the closest ALLOWED value for each field:
    - duration: #{Trip::DURATIONS.inspect}
    - budget: #{Trip::BUDGETS.inspect}
    - mood: #{Trip::MOODS.inspect}
    - energy: #{Trip::ENERGIES.inspect}
    - travel_style: #{Trip::STYLES.inspect}
    - interests: any subset of #{Trip::INTEREST_OPTIONS.inspect}

    Infer sensible values when not stated. If no city is mentioned, use "".
    Respond with ONLY the JSON object — no markdown fences.
  PROMPT

  def self.call(brief)
    new(brief).call
  end

  def initialize(brief)
    @brief = brief.to_s.strip.first(MAX_BRIEF)
  end

  # Returns a Hash of sanitised Trip attributes (string keys -> values).
  def call
    return {} if @brief.blank?

    raw = AnthropicClient.available? ? ai_parse : {}
    sanitize(raw)
  rescue => e
    Rails.logger.warn("[TripBriefParser] parse failed, using defaults: #{e.message}")
    sanitize({})
  end

  private

  def ai_parse
    text = AnthropicClient.chat(
      system_prompt: SYSTEM_PROMPT,
      messages: [{ role: "user", content: @brief }],
      max_tokens: 300
    )
    parse_json(text)
  end

  def parse_json(raw)
    text = raw.to_s.strip.sub(/\A```(?:json)?\s*/i, "").sub(/\s*```\z/, "")
    if (open = text.index("{")) && (close = text.rindex("}"))
      text = text[open..close]
    end
    JSON.parse(text)
  end

  # Force every field into an allowed value; missing city stays blank so the
  # caller can route to the guided form.
  def sanitize(h)
    h ||= {}
    {
      "city"         => h["city"].to_s.strip,
      "duration"     => allowed(h["duration"], Trip::DURATIONS, "5 hours"),
      "budget"       => allowed(h["budget"], Trip::BUDGETS, "medium"),
      "mood"         => allowed(h["mood"], Trip::MOODS, "tired but curious"),
      "energy"       => allowed(h["energy"], Trip::ENERGIES, "medium"),
      "travel_style" => allowed(h["travel_style"], Trip::STYLES, "balanced"),
      "interests"    => Array(h["interests"]).map(&:to_s) & Trip::INTEREST_OPTIONS
    }
  end

  def allowed(value, options, default)
    v = value.to_s.strip.downcase
    options.find { |o| o.downcase == v } || default
  end
end
