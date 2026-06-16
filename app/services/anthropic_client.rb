# Thin wrapper around the official Anthropic (Claude) Ruby SDK.
# Returns the assistant's text, or raises so callers can fall back to a mock.
# Never logs the API key or full prompts.
class AnthropicClient
  # Default to the latest, most capable model. Override with ANTHROPIC_MODEL
  # (e.g. "claude-haiku-4-5" for a cheaper/faster demo).
  DEFAULT_MODEL = "claude-opus-4-8".freeze

  def self.available?
    key = ENV["ANTHROPIC_API_KEY"]
    key.present? && key != "your_api_key_here"
  end

  def self.model
    ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL)
  end

  # system_prompt: String
  # messages:      Array of { role: "user"|"assistant", content: String }
  def self.chat(system_prompt:, messages:, max_tokens: 2048)
    raise "No API key" unless available?

    client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
    response = client.messages.create(
      model: model,
      max_tokens: max_tokens,
      system_: system_prompt,
      messages: messages
    )

    text = response.content.find { |block| block.type == :text }&.text
    raise "Empty AI response" if text.nil? || text.strip.empty?
    text
  end
end
