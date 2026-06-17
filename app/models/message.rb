class Message < ApplicationRecord
  belongs_to :chat
  has_one_attached :file

  ROLES = %w[user assistant].freeze
  MAX_CONTENT = 1000 # guard rail: cap how long a single user message can be

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true, unless: -> { file.attached? }
  # Only guard user input length; assistant replies are already capped by max_tokens.
  validates :content, length: { maximum: MAX_CONTENT }, if: -> { from_user? }

  scope :ordered, -> { order(:created_at) }

  def from_user?;      role == "user"; end
  def from_assistant?; role == "assistant"; end
end
