ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Do not run tests in parallel, since we're using a single Chromehelper instance parallelizing will screw everything up.
  parallelize(workers: 1)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  i_suck_and_my_tests_are_order_dependent!()

  # Add more helper methods to be used by all tests here...

  # Change an environmental variable for just the block, this is important because ENV variables are
  # constant for the *entire* test run, so we need to reset it at the end otherwise it persists
  #
  # Note: I'm just going to assume this isn't thread-safe
  def modify_environment_variable(variable_name, temp_variable_value, &block)
    original_variable_value = ENV[variable_name]
    ENV[variable_name] = temp_variable_value
    yield
    ENV[variable_name] = original_variable_value
  end

  if `uname`.strip == "Darwin"
    Minitest.after_run {
      `osascript -e 'display notification "All Hypatia tests have finished up!" with title "Test Completed"'`
    }
  end

  # This means it's running on our custom CI server
  # if Net::Ping::HTTP.new("https://localhost:2345").ping?
    Typhoeus.post("https://localhost:2345/test_completed",
    headers: { "Content-Type": "application/json" },
    body: { vm_id: "testing123", status_code: 200, status_message: "WOOOOOOOO" }.to_json)
  # end
end
