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
      arr.each_with_object([]) do |i, arr|
        definition = ref.definition(i[:text])
        next unless definition

        back = %(#{definition}\n\n"#{i[:context]}")
        arr.push(front: i[:text], back: back)
        # TODO: do something with the ones without definitions?
      end
    end

    private

    def parse
      file = File.read("input.csv")
      CSV.parse(file, headers: true, header_converters: :symbol).map { |h| h.to_h.compact }
    end
  end
end
