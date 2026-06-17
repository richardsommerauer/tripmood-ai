# Idempotent seeds for the production demo. Safe to run repeatedly:
# find_or_initialize_by means re-running won't duplicate trips or destroy data.
puts "Seeding TripMood AI…"

demo = User.find_or_initialize_by(email: "demo@tripmood.ai")
demo.password = "password123" if demo.new_record?
demo.save!

# Polished demo trips for the intermediate demo. `title` is a curated display
# name; the rest of the plan (summary, stops, tips) is generated from the inputs
# (real AI when ANTHROPIC_API_KEY is set, otherwise the built-in mock).
SAMPLES = [
  { title: "Foodie Tuk Tuk Evening in Bangalore",
    city: "Bangalore", duration: "3 hours", budget: "low", mood: "foodie",
    energy: "high", travel_style: "packed",
    interests: ["food", "markets", "hidden gems"] },

  { title: "Rainy Day Culture Escape in Lisbon",
    city: "Lisbon", duration: "full day", budget: "medium", mood: "cultural",
    energy: "medium", travel_style: "balanced",
    interests: ["culture", "cafés", "photography"] },

  { title: "Budget Market & Coffee Walk in Bangalore",
    city: "Bangalore", duration: "5 hours", budget: "low", mood: "calm",
    energy: "medium", travel_style: "relaxed",
    interests: ["cafés", "markets", "walking"] },

  { title: "Relaxed Solo Explorer Day in Lisbon",
    city: "Lisbon", duration: "full day", budget: "medium", mood: "calm",
    energy: "low", travel_style: "relaxed",
    interests: ["walking", "nature", "photography"] }
]

SAMPLES.each do |attrs|
  attrs = attrs.dup
  display_title = attrs.delete(:title)

  # Identify a trip by its curated title so re-seeding updates in place.
  trip = demo.trips.find_or_initialize_by(title: display_title)
  trip.assign_attributes(attrs)
  trip.plan    = TripPlanGenerator.call(trip)
  trip.title   = display_title
  trip.summary = trip.plan["summary"]
  trip.save!
  puts "  ✓ #{trip.title}"
end

puts "Done. Demo login: demo@tripmood.ai / password123"
