class Message < ApplicationRecord
  belongs_to :chat
  has_one_attached :file

  ROLES = %w[user assistant].freeze

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true, unless: -> { file.attached? }

  scope :ordered, -> { order(:created_at) }

  def from_user?;      role == "user"; end
  def from_assistant?; role == "assistant"; end
end
