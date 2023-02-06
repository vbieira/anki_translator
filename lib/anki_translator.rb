# frozen_string_literal: true

require "dotenv"
require "csv"
require "faraday"

require_relative "anki_translator/csv_manager"
require_relative "anki_translator/references"
require_relative "anki_translator/version"

Dotenv.load

module AnkiTranslator
  class Error < StandardError; end
end
