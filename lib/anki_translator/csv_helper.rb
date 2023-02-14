# frozen_string_literal: true

module AnkiTranslator
  class CSVHelper
    DEFAULT_INPUT_FILE = "input.csv"
    DEFAULT_OUTPUT_FILE = "output.csv"

    attr_reader :notes, :references, :total

    def initialize(input = DEFAULT_INPUT_FILE, _output = DEFAULT_OUTPUT_FILE)
      @notes = parse(input)
      @total = @notes.count
      @references = References.new
    end

    def generate
      add_references
      write(anki_cards)
    end

    private

    attr_writer :notes

    def anki_cards
      notes.map do |note|
        back = parse_translation(note.translation) +
               parse_definition(note.definition) +
               parse_context(note.text, note.context)
        { front: note.text.downcase, back: back }
      end
    end

    def write(array, filename = DEFAULT_OUTPUT_FILE)
      csv = CSV.generate do |row|
        array.each { |hash| row << hash.values }
      end
      File.write(filename, csv)
    end

    def add_references
      notes.each_with_index do |note, i|
        puts %([#{i + 1}/#{total}] "#{note.text}")
        references.search(note.text)
        note.definition = fetch_definition(note.text)
        note.translation = references.translate
      end
    end

    def fetch_definition(text)
      puts "fetch_definition"
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
