# frozen_string_literal: true

module AnkiTranslator
  module References
    class GoogleTranslate
      URL = "https://translate.google.com/"
      TARGET_LANGUAGE = "pt"

      attr_reader :session, :name

      def initialize
        @name = :google_translate
        @session = new_session
      end

      def fetch_definitions(term)
        search(term)
        return unless session.has_selector?("h3", text: "Definitions of ")

        definitions = session.find("h3", text: "Definitions of ")&.all(:xpath, ".//..")&.first&.all("div[lang=en]")
        parse_definitions(definitions) + translations
      rescue Selenium::WebDriver::Error::StaleElementReferenceError
        new_session
        nil
      end

      private

      attr_writer :session

      def new_session
        s = Capybara::Session.new(:chrome)
        s.visit("#{URL}?sl=en&tl=#{TARGET_LANGUAGE}&op=translate")
        s
      end

      def search(term)
        input_element = session.all("span[lang=en]").first
        return search(term) if input_element.nil?

        text_area = input_element.find("textarea")
        text_area.set(term)
        text_area.native.send_keys(:return)
        sleep 3
      end

      def clear_search
        search_element = session.all("span[lang=en]").first
        return if search_element.nil?

        search_element.find("textarea").set("")
      end

      Translation = Struct.new(:text, :source)
      def translations
        return unless session.has_selector?("h3", text: "Translations of")

        session.find("table").all("th[scope=row]")[0..2].map do |t|
          Translation.new(text: t.text, source: name)
        end
      end

      Definition = Struct.new(:text, :examples, :source)
      def parse_definitions(definitions)
        (0...definitions.count).step(2).map do |i|
          definition = definitions[i].text
          quote = definitions[i + 1]&.text
          Definition.new(text: definition, examples: quote, source: name)
        end
      end
    end
  end
end
