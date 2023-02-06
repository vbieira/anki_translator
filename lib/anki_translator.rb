# frozen_string_literal: true

require "dotenv"

require_relative "anki_translator/version"

Dotenv.load

module AnkiTranslator
  class Error < StandardError; end
  # Your code goes here...
end
