# frozen_string_literal: true

RSpec.describe Reforge::Extractor do
  subject(:instance) { described_class.new(**args) }

  let(:args) { { type: :key, args: [:key] } }

  describe "#extract_from" do
    subject(:extract_from) { instance.extract_from(:source) }

    let(:implementation) { instance_double(described_class::KeyExtractor) }

    before do
      allow(instance).to receive(:implementation).and_return(implementation)
      allow(implementation).to receive(:extract_from).and_return(:extracted_value)
    end

    it "delegates to the implementation" do
      expect(extract_from).to be :extracted_value
      expect(implementation).to have_received(:extract_from).once.with(:source)
    end

    context "when a transform is provided" do
      let(:args) { { type: :key, args: [:key], transform: ->(v) { v.to_s } } }

      it "delegates to the implementation and transforms the value" do
        expect(extract_from).to eq "extracted_value"
        expect(implementation).to have_received(:extract_from).once.with(:source)
      end
    end
  end

  describe "#implementation" do
    subject(:implementation) { instance.implementation }

    context "when initialized with 'type: key'" do
      let(:args) { { type: :key, args: [:key] } }

      before { allow(described_class::KeyExtractor).to receive(:new).and_call_original }

      it "forwards args to create a KeyExtractor implementation" do
        expect(implementation).to be_an_instance_of described_class::KeyExtractor
        expect(described_class::KeyExtractor).to have_received(:new).once.with(:key)
      end
    end

    context "when initialized with 'type: value'" do
      let(:args) { { type: :value, args: [10] } }

      before { allow(described_class::ValueExtractor).to receive(:new).and_call_original }

      it "forwards args to create a ValueExtractor implementation" do
        expect(implementation).to be_an_instance_of described_class::ValueExtractor
        expect(described_class::ValueExtractor).to have_received(:new).once.with(10)
      end
    end
  end

  describe "#transform" do
    subject(:transform_attr) { instance.transform }

    context "when no transform is supplied" do
      let(:args) { { type: :key, args: [:key] } }

      it "does not set the transform" do
        expect(transform_attr).to be_nil
      end
    end

    context "when an invalid transform is supplied" do
      let(:args) { { type: :key, args: [:key], transform: {} } }

      it "raises an ArgumentError during initialization" do
        expect { instance }.to raise_error ArgumentError, "Transform must be a Proc"
      end
    end

    context "when a valid transform is supplied" do
      let(:args) { { type: :key, args: [:key], transform: transform } }
      let(:transform) { ->(v) { v.to_s } }

      it "sets the transform" do
        expect(transform_attr).to be transform
      end
    end
  end
end
