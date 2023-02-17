# frozen_string_literal: true

module AnkiTranslator
  module References
    class MacmillanDictionary
      URL = "https://www.macmillandictionary.com/"

      attr_reader :session, :name

      def initialize
        @name = :macmillan
        @session = Capybara::Session.new(:chrome)
        @session.visit(URL)
        @session.click_button("I Accept")
      end

      Definition = Struct.new(:text, :examples, :source)
      def fetch_definitions(term)
        search(term)
        definitions = session.all("span", class: "DEFINITION")
        return nil unless definitions&.any?

        definitions.map do |d|
          examples = find_examples(d)
          Definition.new(text: d.text, examples: examples, source: name)
        end
      end

      private

      def search(term)
        input = session.find("div", class: "search-container").find("input")
        input.set(term)
        input.native.send_keys(:return)
      end

      def find_examples(element)
        parent = element.first(:xpath, ".//..")
        if parent.has_selector?("span", class: "EXAMPLE")
          parent.all("span", class: "EXAMPLE").map(&:text)
        elsif parent.has_selector?("div", class: "openEx")
          parent.all("div", class: "openEx").map(&:text)
        end
      end
    end
  end
end
