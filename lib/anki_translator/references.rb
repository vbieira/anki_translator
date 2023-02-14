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
      sleep 1
      input_element = session.all("span[lang=en]").first
      return search(text) if input_element.nil?

      text_area = input_element.find("textarea")
      text_area.set(text)
      text_area.native.send_keys(:return)
      sleep 2
    end

    def definition
      return nil unless session.has_selector?("h3", text: "Definitions of ")

      definitions = session.find("h3", text: "Definitions of ")&.all(:xpath, ".//..")&.first&.all("div[lang=en]")
      parse_definitions(definitions)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      new_session
      nil
    end

    def translate
      return nil unless session.has_selector?("h3", text: "Translations of")

      session.find("table").all("th[scope=row]")[0..2].map(&:text)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      new_session
      nil
    end

    private

    attr_writer :session

    def new_session
      @session = Capybara::Session.new(:chrome)
      @session.visit("#{GOOGLE_TRANSLATE_URL}?sl=en&tl=pt&op=translate")
    end

    def parse_definitions(definitions)
      (0...definitions.count).step(2).map do |i|
        definition = definitions[i].text
        quote = definitions[i + 1]&.text
        %(#{definition} "#{quote}")
      end
    end
  end
end
