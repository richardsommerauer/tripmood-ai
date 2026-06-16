# Idempotent seeds for demos. Safe to run repeatedly.
puts "Seeding TripMood AI…"

demo = User.find_or_initialize_by(email: "demo@tripmood.ai")
demo.password = "password123" if demo.new_record?
demo.save!

SAMPLES = [
  { city: "Bangalore", duration: "5 hours", budget: "low", mood: "tired but curious",
    energy: "low", travel_style: "relaxed", interests: ["food", "culture", "cafés"] },
  { city: "Lisbon", duration: "full day", budget: "medium", mood: "romantic",
    energy: "medium", travel_style: "balanced", interests: ["cafés", "walking", "photography"] },
  { city: "Bangkok", duration: "3 hours", budget: "low", mood: "foodie",
    energy: "high", travel_style: "packed", interests: ["food", "markets", "hidden gems"] }
]

SAMPLES.each do |attrs|
  trip = demo.trips.find_or_initialize_by(city: attrs[:city], mood: attrs[:mood])
  trip.assign_attributes(attrs)
  trip.plan = TripPlanGenerator.call(trip)
  trip.title = trip.plan["title"]
  trip.summary = trip.plan["summary"]
  trip.save!
  puts "  ✓ #{trip.title}"
end

puts "Done. Demo login: demo@tripmood.ai / password123"
