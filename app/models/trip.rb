class Trip < ApplicationRecord
  belongs_to :user
  has_many :chats, dependent: :destroy

  DURATIONS = ["2 hours", "3 hours", "5 hours", "full day"].freeze
  BUDGETS   = %w[low medium high].freeze
  MOODS     = ["tired but curious", "adventurous", "romantic", "family-friendly",
               "cultural", "foodie", "calm", "social"].freeze
  ENERGIES  = %w[low medium high].freeze
  STYLES    = %w[relaxed balanced packed].freeze
  INTEREST_OPTIONS = ["food", "culture", "nature", "temples", "markets", "cafés",
                      "hidden gems", "shopping", "walking", "photography"].freeze

  before_validation { self.interests = Array(interests).reject(&:blank?) }

  validates :city, presence: true
  validates :duration, inclusion: { in: DURATIONS, message: "please choose how much time you have" }
  validates :budget,   inclusion: { in: BUDGETS,   message: "please choose a budget" }
  validates :mood,     inclusion: { in: MOODS,     message: "please choose a mood" }
  validates :energy,   inclusion: { in: ENERGIES,  message: "please choose an energy level" }
  validates :travel_style, inclusion: { in: STYLES, message: "please choose a travel style" }

  # plan is a Hash stored as jsonb; expose its parts with safe defaults.
  def stops;           Array(plan["stops"]); end
  def why_mood;        plan["whyMood"]; end
  def budget_tips;     Array(plan["budgetTips"]); end
  def transport_tips;  Array(plan["transportTips"]); end
  def safety_tips;     Array(plan["safetyTips"]); end
  def relaxed_alt;     plan["relaxedAlternative"]; end
  def reminder;        plan["reminder"] || "Please check current opening hours before you go."; end
  def ai_source;       plan["source"] || "mock"; end

  def interests_sentence
    interests.present? ? interests.join(", ") : "a bit of everything"
  end
end
