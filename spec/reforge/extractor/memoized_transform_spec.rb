# frozen_string_literal: true

RSpec.describe Reforge::Extractor::MemoizedTransform do
  subject(:instance) { described_class.new(transform, **memoize_configuration) }

  let(:transform) { nil }
  let(:memoize_configuration) { {} }

  describe "#call" do
    subject(:call) { instance.call(10) }

    let(:transform) { instance_double(Proc) }

    before { allow(transform).to receive(:call).and_return("10") }

    it "delegates to the underlying transform" do
      expect(call).to eq "10"
      expect(transform).to have_received(:call).once.with(10)
    end

    context "when already called with the same value" do
      let!(:first_result) { instance.call(10) }

      it "returns the same value in both cases, but delegates to the transform once" do
        expect(call).to eq first_result
        expect(transform).to have_received(:call).once.with(10)
      end
    end

    context "when the :by option has been specified" do
      let(:memoize_configuration) { { by: ->(v) { v.to_s.first } } }

      it "delegates to the underlying transform" do
        expect(call).to eq "10"
        expect(transform).to have_received(:call).once.with(10)
      end

      context "when already called with a different value which uses the same memo key" do
        let!(:first_result) { instance.call(100) }

        it "returns the same value in both cases, but delegates to the transform once" do
          expect(call).to eq first_result
          expect(transform).to have_received(:call).once.with(10)
        end
      end
    end
  end

  context "when no transform is supplied" do
    let(:transform) { nil }

    it "raises an ArgumentError during initialization" do
      expect { instance }.to raise_error ArgumentError, "The transform must be callable"
    end
  end

  context "when an invalid transform is supplied" do
    let(:transform) { :not_callable }

    it "raises an ArgumentError during initialization" do
      expect { instance }.to raise_error ArgumentError, "The transform must be callable"
    end
  end

  context "when an invalid :by option has been supplied in the configuration hash" do
    let(:transform) { ->(v) { v.to_s } }
    let(:memoize_configuration) { { by: 10 } }

    it "raises an ArgumentError during initialization" do
      expect { instance }.to raise_error ArgumentError, "The :by option of the configuration hash must be callable"
    end
  end
end
