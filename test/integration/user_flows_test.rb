require "test_helper"

class UserFlowsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "flow@example.com", password: "password123")
  end

  test "landing page loads" do
    get root_path
    assert_response :success
    assert_match "matched to your", response.body
  end

  test "trips index is public" do
    get trips_path
    assert_response :success
  end

  test "new trip requires login" do
    get new_trip_path
    assert_redirected_to new_user_session_path
  end

  test "logged-in user creates a trip with a mock plan" do
    sign_in @user
    assert_difference "Trip.count", 1 do
      post trips_path, params: { trip: {
        city: "Bangalore", duration: "5 hours", budget: "low", mood: "tired but curious",
        energy: "low", travel_style: "relaxed", interests: ["food", "culture"]
      } }
    end
    trip = Trip.last
    assert_equal "mock", trip.ai_source
    assert trip.stops.size.between?(3, 5)
    assert_redirected_to trip
  end

  test "invalid trip shows validation errors" do
    sign_in @user
    assert_no_difference "Trip.count" do
      post trips_path, params: { trip: { city: "", duration: "bogus" } }
    end
    assert_response :unprocessable_entity
  end

  test "chat with AI: message gets an assistant reply (mock)" do
    sign_in @user
    trip = @user.trips.create!(city: "Bangalore", duration: "5 hours", budget: "low",
      mood: "tired but curious", energy: "low", travel_style: "relaxed",
      interests: ["food"], plan: { "stops" => [] })
    chat = trip.chats.create!(user: @user, title: "Test chat")

    assert_difference "chat.messages.count", 2 do # user message + assistant reply
      post chat_messages_path(chat), params: { message: { content: "Make it cheaper" } }
    end
    assert_equal "assistant", chat.messages.ordered.last.role
    assert_redirected_to chat
  end

  test "user cannot edit another user's trip" do
    other = User.create!(email: "other@example.com", password: "password123")
    trip = other.trips.create!(city: "Lisbon", duration: "3 hours", budget: "low",
      mood: "calm", energy: "low", travel_style: "relaxed", plan: {})
    sign_in @user
    get edit_trip_path(trip)
    assert_redirected_to trips_path
  end

  test "missing API key does not crash generation" do
    sign_in @user
    trip = @user.trips.new(city: "Paris", duration: "2 hours", budget: "high",
      mood: "romantic", energy: "high", travel_style: "balanced", interests: [])
    plan = TripPlanGenerator.call(trip)
    assert_equal "mock", plan["source"]
    assert plan["stops"].any?
  end
end
