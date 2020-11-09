# frozen_string_literal: true

RSpec.describe Reforge::Tree::ExtractorNode do
  subject(:instance) { described_class.new(extractor) }

  let(:extractor) { nil }

  context "when no extractor is supplied" do
    let(:extractor) { nil }

    it "raises during initialization" do
      expect { instance }.to raise_error ArgumentError, "The extractor must be a Reforge::Extractor"
    end
  end

  context "when an invalid extractor is supplied" do
    let(:extractor) { "hello" }

    it "raises during initialization" do
      expect { instance }.to raise_error ArgumentError, "The extractor must be a Reforge::Extractor"
    end
  end

  context "when a valid extractor is supplied" do
    let(:extractor) { instance_double(Reforge::Extractor) }

    before { allow(extractor).to receive(:is_a?).with(Reforge::Extractor).and_return(true) }

    describe "#reforge" do
      subject(:reforge) { instance.reforge(:source) }

      before { allow(extractor).to receive(:extract_from).and_return(:result) }

      it "delegates to the extractor" do
        expect(reforge).to be :result
        expect(extractor).to have_received(:extract_from).once.with(:source)
      end
    end
  end
end
