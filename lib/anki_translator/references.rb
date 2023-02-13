# frozen_string_literal: true

module AnkiTranslator
  class References
    MERRIAM_WEBSTER_API = "https://www.dictionaryapi.com/api/v3/references/collegiate/json/"
    GOOGLE_TRANSLATE_URL = "https://translate.google.com/"

    attr_reader :conn, :session

    def initialize
      params = { key: ENV["MERRIAM_WEBSTER_API_KEY"] }
      headers = { "Content-Type" => "application/json" }
      @conn = Faraday.new(url: MERRIAM_WEBSTER_API, params: params, headers: headers) do |f|
        f.response :json
      end
      @session = Capybara::Session.new(:chrome)
      session.visit("#{GOOGLE_TRANSLATE_URL}?sl=en&tl=pt&op=translate")
    end

    def mw_definition(term)
      puts "\"#{term}\" definition [MW]..."
      escaped_term = CGI.escape(term)
      body = conn.get(escaped_term).body.first
      body.is_a?(Hash) && body.key?("shortdef") ? body["shortdef"] : nil
    end

    def search(text)
      puts "\"#{text}\" definition..."
      input = session.all("span[lang=en]").first.find("textarea")
      input.set(text)
      input.native.send_keys(:return)
      sleep 2
    end

    def definition
      return nil unless session.has_css?("h3", text: "Definitions of ")

      definitions_div = session.find("h3", text: "Definitions of ")
      parent_div = definitions_div.all(:xpath, ".//..")&.first
      definitions = parent_div.all("div[lang=en]")
      (0...definitions.count).step(2).map do |i|
        definition = definitions[i].text
        quote = definitions[i + 1]&.text
        %(#{definition} "#{quote}")
      end
    end

    def translate
      return nil unless session.has_css?("h3", text: "Translations of")

      session.find("table").all("th[scope=row]")[0..2].map(&:text)
    end
  end
end
