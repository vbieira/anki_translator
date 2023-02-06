# frozen_string_literal: true

module AnkiTranslator
  class References
    attr_reader :conn

    URL = "https://www.dictionaryapi.com/api/v3/references/collegiate/json/"

    def initialize
      params = { key: ENV["MERRIAM_WEBSTER_API_KEY"] }
      headers = { "Content-Type" => "application/json" }
      @conn = Faraday.new(url: URL, params: params, headers: headers) do |f|
        f.response :json
      end
    end

    def definition(term)
      puts "fetching \"#{term}\" definition..."
      escaped_term = CGI.escape(term)
      body = conn.get(escaped_term).body.first
      body.is_a?(Hash) && body.key?("shortdef") ? body["shortdef"].join("\n") : nil
    end
  end
end
