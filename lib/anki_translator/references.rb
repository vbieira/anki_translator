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
        source_options = {
          macmillan_dictionary: MacmillanDictionary,
          merriam_webster: MerriamWebster,
          google_translate: GoogleTranslate
        }.freeze

        @sources ||= AnkiTranslator.configuration.sources.map do |s|
          source_options.include?(s) ? source_options[s].new : nil
        end.compact
      end
    end
  end
end
