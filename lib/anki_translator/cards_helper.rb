# frozen_string_literal: true

module AnkiTranslator
  class CardsHelper
    DEFAULT_INPUT_FILE = "input.csv"
    DEFAULT_OUTPUT_FILE = "output.csv"

    def initialize(input_file = DEFAULT_INPUT_FILE, output_file = DEFAULT_OUTPUT_FILE)
      @notes = parse(input_file)
      @total = @notes.count
      @references = References.new
      @output_file = output_file
    end

    def generate
      notes.each_with_index do |note, i|
        print %(\n[#{(i / total.to_f * 100).round(2)}%] "#{note.text}")
        add_reference(note)
      end
      write(anki_cards, output_file)
    end

    private

    attr_accessor :notes
    attr_reader :references, :total, :output_file

    def anki_cards
      notes.map do |note|
        back = parse_translation(note.translation) +
               parse_definition(note.definition) +
               parse_context(note.text, note.context)
        { front: note.text.downcase, back: back }
      end
    end

    def write(array, filename)
      csv = CSV.generate do |row|
        array.each { |hash| row << hash.values }
      end
      File.write(filename, csv)
      filename
    end

    def add_reference(note)
      references.search(note.text)
      note.definition = fetch_definition(note.text)
      note.translation = references.translate
      references.clear_search
    end

    def fetch_definition(text)
      gt_definition = references.definition
      return gt_definition unless gt_definition.nil?

      references.mw_definition(text)
    end

    def parse_context(text, context)
      return "" unless context

      "#{context.gsub(text, "<strong>#{text}</strong>")}\n"
    end

    def parse_translation(translation)
      return "" unless translation

      "#{translation.join(", ")}\n"
    end

    def parse_definition(definitions)
      return "" unless definitions&.any?

      lis = definitions.map { |definition| "<li>#{definition}</li>" }
      "<ol>#{lis.join("")}</ol>"
    end

    Note = Struct.new(:text, :context, :definition, :translation)
    def parse(filename)
      file = File.read(filename)
      arr = CSV.parse(file, headers: true, header_converters: :symbol)
      arr.map { |h| Note.new(*h.values_at(*Note.members)) }
    end
  end
end
