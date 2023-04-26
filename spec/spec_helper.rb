# frozen_string_literal: true

require "anki_translator"
require "pry"
require "vcr"

SENSITIVE_ENV_VARS = %w[
  MERRIAM_WEBSTER_API_KEY
].freeze

VCR.configure do |config|
  config.cassette_library_dir = "fixtures/vcr_cassettes"
  config.hook_into :webmock

  SENSITIVE_ENV_VARS.each do |var|
    config.filter_sensitive_data("<#{var}>") { ENV[var] }
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

load "bin/configure"
