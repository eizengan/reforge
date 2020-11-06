# frozen_string_literal: true

RSpec.describe Reforge::Extractor::ValueExtractor do
  subject(:instance) { described_class.new(value) }

  let(:value) { nil }

  describe "#extract_from" do
    subject(:extract_from) { instance.extract_from(source) }

    let(:value) { 10 }
    let(:source) { :whatever }

    it "returns the stored value" do
      expect(extract_from).to be 10
    end
  end
end
