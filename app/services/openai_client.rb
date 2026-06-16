require "net/http"
require "json"

# Thin OpenAI Chat Completions client (no extra gem).
# Returns the assistant message string, or raises on failure so callers
# can fall back to a mock. Never logs the API key or full prompts.
class OpenaiClient
  ENDPOINT = URI("https://api.openai.com/v1/chat/completions")

  def self.available?
    key = ENV["OPENAI_API_KEY"]
    key.present? && key != "your_api_key_here"
  end

  # messages: array of { role:, content: }; json: request a JSON object back.
  def self.chat(messages, json: false, temperature: 0.8)
    raise "No API key" unless available?

    http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
    http.use_ssl = true
    http.read_timeout = 30

    req = Net::HTTP::Post.new(ENDPOINT)
    req["Content-Type"]  = "application/json"
    req["Authorization"] = "Bearer #{ENV['OPENAI_API_KEY']}"
    body = {
      model: ENV.fetch("OPENAI_MODEL", "gpt-4o-mini"),
      messages: messages,
      temperature: temperature
    }
    body[:response_format] = { type: "json_object" } if json
    req.body = body.to_json

    res = http.request(req)
    raise "OpenAI #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    content = JSON.parse(res.body).dig("choices", 0, "message", "content")
    raise "Empty AI response" if content.blank?
    content
  end
end
