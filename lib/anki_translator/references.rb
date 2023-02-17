# frozen_string_literal: true

module AnkiTranslator
  module References
    class << self
      def definitions(term)
        sources.map { |s| s.fetch_definitions(term) }.flatten.compact
      end

      private

      def sources
        @sources ||= [MacmillanDictionary.new, MerriamWebster.new, GoogleTranslate.new]
      end
    end
  end
end
