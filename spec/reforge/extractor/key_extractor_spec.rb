# frozen_string_literal: true

RSpec.describe Reforge::Extractor::KeyExtractor do
  subject(:instance) { described_class.new(key) }

  let(:key) { nil }

  describe "#extract_from" do
    subject(:extract_from) { instance.extract_from(source) }

    let(:source) { nil }

    context "when the source is a Hash" do
      let(:source) { { foo: 1, bar: 2 } }
      let(:key) { :foo }

      it "extracts the value at the stored key" do
        expect(extract_from).to be 1
      end
    end

    context "when the source is an Array" do
      let(:source) { [1, 2, 3] }
      let(:key) { 1 }

      it "extracts the value at the stored key" do
        expect(extract_from).to be 2
      end
    end
  end
end
