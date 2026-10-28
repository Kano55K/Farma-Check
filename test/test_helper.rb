ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/api_test_helper"

module ActiveSupport
  class TestCase
    # En Windows no hay fork y la paralelización con threads comparte la conexión SQLite
    # (provoca "cannot start a transaction within a transaction"), así que ahí se corre en serie.
    parallelize(workers: Gem.win_platform? ? 1 : :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
