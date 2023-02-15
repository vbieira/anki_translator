# frozen_string_literal: true

module AnkiTranslator
  class CardsHelper
    DEFAULT_INPUT_FILE = "input.csv"
    DEFAULT_OUTPUT_FILE = "output.csv"

    attr_reader :notes

    def initialize(input_file = DEFAULT_INPUT_FILE, output_file = DEFAULT_OUTPUT_FILE)
      @notes = parse(input_file)
      @total = @notes.count
      @references = References.new
      @output_file = output_file
    end

    def generate(start_at = 0, end_at = total)
      notes[start_at..end_at].each_with_index do |note, i|
        print %(\n#{i + start_at}/#{end_at})
        add_reference(note)
      end
      write(anki_cards[start_at..end_at], "#{start_at}-#{end_at}-#{output_file}")
    end

    private

    attr_writer :notes
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
      references.search(parse_search_text(note.text))
      note.definition = fetch_definition(note.text)
      note.translation = fetch_translation
      references.clear_search
    end

    def parse_search_text(text)
      text.gsub("<br>", "")
    end

    def fetch_translation
      translation = references.translate
      print " [no translation]" unless translation
      translation
    end

    def fetch_definition(text)
      definition = references.definition
      return definition unless definition.nil?

      definition = references.mw_definition(text)
      print " [no definition]" unless definition
      definition
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
      anki_file = filename.match?(/.txt$/)
      if anki_file
        puts "parsing Anki file..."
        arr = CSV.parse(file, col_sep: "\t")
        arr.map { |a| Note.new(text: a.first) }
      else
        arr = CSV.parse(file, headers: true, header_converters: :symbol)
        arr.map { |h| Note.new(*h.values_at(*Note.members)) }
      end
    end
  end
end
