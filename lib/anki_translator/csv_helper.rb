# frozen_string_literal: true

module AnkiTranslator
  class CSVHelper
    DEFAULT_INPUT_FILE = "input.csv"
    DEFAULT_OUTPUT_FILE = "output.csv"

    attr_reader :notes, :references

    def initialize(input = DEFAULT_INPUT_FILE, _output = DEFAULT_OUTPUT_FILE)
      @notes = parse(input)
      @references = References.new
    end

    def generate
      add_definitions
      anki_card
    end

    private

    attr_writer :notes

    def anki_card
      parse_context
      # TODO: get anki stuff and add better translations to update them
      # TODO: do something with the ones without definitions?
    end

    def write(array, filename = DEFAULT_OUTPUT_FILE)
      headers = array.first.keys
      csv = CSV.generate do |row|
        row << headers
        array.each { |hash| row << hash.values }
      end
      File.write(filename, csv)
    end

    def add_definitions
      notes.each do |note|
        references.search(note.text)
        note.definition = references.definition
        note.definition = references.mw_definition(note.text) if note.definition.nil?
        note.translation = references.translate
      end
    end

    def parse_context
      sentences_regex = /\s+[^.!?]*[.!?]/
      notes.each do |note|
        sentences = note.context.scan(sentences_regex)
        filter_context = sentences.select { |s| s.include?(note.text) }.first&.strip || note.context
        note.context = filter_context.gsub(note.text, "<strong>#{note.text}</strong>")
      end
    end

    Note = Struct.new(:text, :context, :definition, :translation)
    def parse(filename)
      file = File.read(filename)
      arr = CSV.parse(file, headers: true, header_converters: :symbol)
      arr.map { |h| Note.new(*h.values_at(*Note.members)) }
    end
  end
end
