ENV["RAILS_ENV"] ||= "test"

# Tests must never make real (paid) AI calls — always run in mock mode,
# even if a local .env defines ANTHROPIC_API_KEY (dotenv loads it in test).
ENV.delete("ANTHROPIC_API_KEY")

require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
