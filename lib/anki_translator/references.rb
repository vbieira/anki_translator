# frozen_string_literal: true

module AnkiTranslator
  class References
    MERRIAM_WEBSTER_API = "https://www.dictionaryapi.com/api/v3/references/collegiate/json/"
    GOOGLE_TRANSLATE_URL = "https://translate.google.com/"
    MACMILLAN_DICTIONARY = "https://www.macmillandictionary.com/"

    attr_reader :conn, :gt_session, :mm_session

    def initialize
      params = { key: ENV["MERRIAM_WEBSTER_API_KEY"] }
      headers = { "Content-Type" => "application/json" }
      @conn = Faraday.new(url: MERRIAM_WEBSTER_API, params: params, headers: headers) do |f|
        f.response :json
      end
      @gt_session = Capybara::Session.new(:chrome)
      @gt_session.visit("#{GOOGLE_TRANSLATE_URL}?sl=en&tl=pt&op=translate")
      @mm_session = Capybara::Session.new(:chrome)
      @mm_session.visit(MACMILLAN_DICTIONARY)
      @mm_session.visit(MACMILLAN_DICTIONARY)
      @mm_session.click_button("I Accept")
    end

    def mm_definition(term)
      input = mm_session.find("div", class: "search-container").find("input")
      input.set(term)
      input.native.send_keys(:return)
      definitions = mm_session.all("span", class: "DEFINITION")
      return nil unless definitions&.any?

      print " [MM]"
      definitions.map do |d|
        parent = d.first(:xpath, ".//..")
        example = if parent.has_selector?("p", class: "EXAMPLE")
                    parent.all("p", class: "EXAMPLE").map { |e| %("#{e}") }.join("\n")
                  elsif parent.has_selector?("p", class: "OpenEx")
                    parent.all("p", class: "OpenEx").map { |e| %("#{e}") }.join("\n")
                  end
        puts "\n#{d.text}"
        example ? %(#{d.text} "#{example}") : d.text
      end
    end

    def mw_definition(term)
      escaped_term = CGI.escape(term)
      body = conn.get(escaped_term).body.first
      return nil unless body.is_a?(Hash) && body.key?("shortdef")

      definition = body["shortdef"]
      print " [MW]" if definition
      definition
    end

    def search(text)
      input_element = gt_session.all("span[lang=en]").first
      return search(text) if input_element.nil?

      text_area = input_element.find("textarea")
      print %( "#{text}")
      text_area.set(text)
      text_area.native.send_keys(:return)
      sleep 3
    end

    def clear_search
      input_element = gt_session.all("span[lang=en]").first
      return if input_element.nil?

      input_element.find("textarea").set("")
    end

    def definition
      return nil unless gt_session.has_selector?("h3", text: "Definitions of ")

      definitions = gt_session.find("h3", text: "Definitions of ")&.all(:xpath, ".//..")&.first&.all("div[lang=en]")
      parse_definitions(definitions)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      new_session
      nil
    end

    def translate
      return nil unless gt_session.has_selector?("h3", text: "Translations of")

      gt_session.find("table").all("th[scope=row]")[0..2].map(&:text)
    rescue Selenium::WebDriver::Error::StaleElementReferenceError
      new_session
      nil
    end

    private

    attr_writer :gt_session, :mm_session

    def new_session
      @gt_session = Capybara::Session.new(:chrome)
      @gt_session.visit("#{GOOGLE_TRANSLATE_URL}?sl=en&tl=pt&op=translate")
    end

    def parse_definitions(definitions)
      (0...definitions.count).step(2).map do |i|
        definition = definitions[i].text
        quote = definitions[i + 1]&.text
        quote ? %(#{definition} "#{quote}") : definition
      end
    end
  end
end
