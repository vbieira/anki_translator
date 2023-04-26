# frozen_string_literal: true

module AnkiTranslator
  class Configuration
    attr_accessor :merriam_webster_api_url, :merriam_webster_api_key

    def initialize
      @merriam_webster_api_url = "https://www.dictionaryapi.com/api/v3/references/collegiate/json/"
    end
  end
end
