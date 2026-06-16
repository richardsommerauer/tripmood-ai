module TripsHelper
  MOOD_ICONS = {
    "tired but curious" => "face-smile", "adventurous" => "mountain-sun",
    "romantic" => "heart", "family-friendly" => "people-roof",
    "cultural" => "landmark", "foodie" => "utensils",
    "calm" => "leaf", "social" => "people-group"
  }.freeze

  INTEREST_ICONS = {
    "food" => "utensils", "culture" => "landmark", "nature" => "tree",
    "temples" => "place-of-worship", "markets" => "store", "cafés" => "mug-hot",
    "hidden gems" => "gem", "shopping" => "bag-shopping",
    "walking" => "person-walking", "photography" => "camera"
  }.freeze

  def mood_icon(mood)     = "fa-solid fa-#{MOOD_ICONS[mood] || 'face-smile'}"
  def interest_icon(i)    = "fa-solid fa-#{INTEREST_ICONS[i] || 'star'}"

  def stop_icon(name)
    n = name.to_s.downcase
    key =
      if    n.match?(/caf|coffee|tea|bookshop/)                  then "mug-hot"
      elsif n.match?(/food|meal|eat|thali|snack|dinner|lunch/)   then "bowl-food"
      elsif n.match?(/museum|cultural|culture|temple|heritage|gallery|monument|palace/) then "landmark"
      elsif n.match?(/market|bazaar|shopping/)                   then "store"
      elsif n.match?(/walk|park|garden|stroll|street/)           then "tree"
      elsif n.match?(/photo|view|sunset|lake/)                   then "camera"
      else                                                            "location-dot"
      end
    "fa-solid fa-#{key}"
  end

  def trip_emoji(trip)
    "fa-solid fa-#{MOOD_ICONS[trip.mood] || 'compass'}"
  end
end
