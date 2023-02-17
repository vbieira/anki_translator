# frozen_string_literal: true

module AnkiTranslator
  module References
    class MerriamWebster
      URL = "https://www.dictionaryapi.com/api/v3/references/collegiate/json/"

      attr_reader :conn, :session, :name

      def initialize
        @name = :merriam_webster
        params = { key: ENV["MERRIAM_WEBSTER_API_KEY"] }
        headers = { "Content-Type" => "application/json" }
        @conn = Faraday.new(url: URL, params: params, headers: headers) do |f|
          f.response :json
        end
      end

      Definition = Struct.new(:text, :examples, :source)
      def fetch_definitions(term)
        definitions = search(term)
        definitions.map do |d|
          Definition.new(text: d, source: name)
        end
      end

      private

      def search(term)
        escaped_term = CGI.escape(term)
        body = conn.get(escaped_term).body.first
        body.is_a?(Hash) && body.key?("shortdef") ? body["shortdef"] : []
      end
    end
  end
end
