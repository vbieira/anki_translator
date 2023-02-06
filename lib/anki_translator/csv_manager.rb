# frozen_string_literal: true

module AnkiTranslator
  class CsvManager
    attr_reader :arr

    def initialize
      @arr = parse
    end

    def write(arr)
      headers = arr.first.keys
      r = CSV.generate do |csv|
        csv << headers
        arr.each { |x| csv << x.values }
      end
      File.write("output.csv", r)
    end

    def add_definitions
      ref = References.new
      arr.map do |hash|
        hash[:definition] = ref.definition(hash[:text])
        hash
      end
    end

    private

    def parse
      file = File.read("input.csv")
      CSV.parse(file, headers: true, header_converters: :symbol).map { |h| h.to_h.compact }
    end
  end
end
