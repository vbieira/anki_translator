# frozen_string_literal: true

module AnkiTranslator
  module References
    Translation = Struct.new(:text, :source)
    Definition = Struct.new(:text, :examples, :source)

    class << self
      def definitions_and_translations(term)
        definitions = sources.map { |s| s.fetch_definitions(term) }.flatten.compact
        definitions.each_with_object([[], []]) do |d, arr|
          d.is_a?(Definition) ? arr[0] << d : arr[1] << d
        end
      end

      def source_names
        sources.map(&:name)
      end

      private

      def sources
        @sources ||= [MacmillanDictionary.new, MerriamWebster.new, GoogleTranslate.new]
      end
    end
  end
end
