# frozen_string_literal: true

# According to this bug (https://github.com/rails/rails/issues/54260),
# `concurrent-ruby` does not require `logger` anymore which leads to
# this error:
#   Failure/Error: require "active_support"
#
#   NameError:
#     uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger
#
# This has been fixed in Rails 7.0+ but not in Rails 6 series. The
# workaround is to manually require it.
require "logger"

require "tzu"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
