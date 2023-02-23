# frozen_string_literal: true

module AnkiTranslator
  class CardsHelper
    DEFAULT_INPUT_FILE = "input.csv"
    DEFAULT_OUTPUT_FILE = "output.csv"

    Note = Struct.new(:text, :context, :definitions, :translations)

    attr_reader :notes

    def initialize(input_file = DEFAULT_INPUT_FILE, output_file = DEFAULT_OUTPUT_FILE)
      @notes = parse(input_file)
      @total = @notes.count
      @output_file = output_file
    end

    def generate(start_at = 0, end_at = total)
      notes[start_at..end_at].each_with_index do |note, i|
        print %(\n#{i + start_at}/#{end_at} "#{note.text}")
        note.definitions, note.translations = References.definitions_and_translations(note.text)
      end
      print_stats(notes[start_at..end_at])
      cards = anki_cards(notes[start_at..end_at])
      write(cards, "#{start_at}-#{end_at}-#{output_file}")
    end

    private

    attr_writer :notes
    attr_reader :references, :total, :output_file

    def anki_cards(selected_notes)
      selected_notes.map do |note|
        back = parse_translations(note.translations) +
               parse_definitions(note.definitions)
        #  parse_context(note.text, note.context)
        # puts "\n-------------------#{note.text}-------------------\n#{back}"
        { front: note.text.downcase, back: back }
      end
    end
    # TODO: cards preview?

    def write(array, filename)
      csv = CSV.generate do |row|
        array.each { |hash| row << hash.values }
      end
      File.write(filename, csv)
      filename
    end

    def print_stats(selected_notes)
      stats = selected_notes.each_with_object([0, 0, 0, 0, 0]) do |c, arr|
        arr[0] += 1 unless c.translations&.any?
        arr[1] += 1 unless c.definitions&.any?
        arr[2] += 1 if c.definitions&.any? { |d| d.source == :google_translate }
        arr[3] += 1 if c.definitions&.any? { |d| d.source == :merriam_webster }
        arr[4] += 1 if c.definitions&.any? { |d| d.source == :macmillan }
      end
      # TODO: print the ones with no definition
      puts "\n\nno translation: #{stats[0]}\nno definition: #{stats[1]}"
      puts "google translate: #{stats[2]}\nmerriam webster: #{stats[3]}"
      puts "macmillan dictionary: #{stats[4]}\n"
    end

    def parse_context(text, context)
      return "" unless context

      "#{context.gsub(text, "<strong>#{text}</strong>")}\n"
    end

    def parse_translations(translations)
      return "" unless translations&.any?

      "#{translations.map(&:text).join(", ")}\n"
    end

    def parse_definitions(definitions)
      return "" unless definitions&.any?

      definitions
        .group_by(&:source)
        .map { |_k, v| ul_elements(v) }
        .join
    end

    def ul_elements(arr)
      lis = arr.map do |d|
        examples = d.examples&.any? ? %( "<em>#{d.examples.join(", ")}</em>") : ""
        "<li>#{d.text}#{examples}</li>"
      end
      "<ul>#{lis.join}</ul>"
    end

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
