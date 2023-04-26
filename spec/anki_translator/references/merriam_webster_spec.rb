# frozen_string_literal: true

require "spec_helper"

RSpec.describe AnkiTranslator::References::MerriamWebster do
  subject(:result) { described_class.new.fetch_definitions("husky") }

  let(:expected_result) do
    [AnkiTranslator::References::Definition.new(text: "hoarse with or as if with emotion", source: :merriam_webster)]
  end

  it "returns definitions" do
    VCR.use_cassette("merriam_webster", record: :once, match_requests_on: %i[method uri body]) do
      expect(result).to eq(expected_result)
    end
  end
end
