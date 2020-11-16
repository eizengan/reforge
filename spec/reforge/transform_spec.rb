# frozen_string_literal: true

RSpec.describe Reforge::Transform do
  subject(:instance) { described_class.new(**args) }

  let(:args) { { transform: { key: :key } } }

  describe "#call" do
    subject(:call) { instance.call(:source) }

    let(:transform) { instance_double(Proc) }

    before do
      allow(instance).to receive(:transform).and_return(transform)
      allow(transform).to receive(:call).and_return(:transformed_value)
    end

    it "delegates to the transform" do
      expect(call).to be :transformed_value
      expect(transform).to have_received(:call).once.with(:source)
    end
  end

  describe "#transform" do
    subject(:transform) { instance.transform }

    context "when initialized with an invalid transform" do
      let(:args) { { transform: 5 } }

      it "raises an ArgumentError during initialization" do
        expect { instance }.to raise_error ArgumentError, "The transform must be callable or a configuration hash"
      end
    end

    context "when initialized with an attribute config hash" do
      let(:args) { { transform: { attribute: :attr } } }

      before { allow(described_class).to receive(:attribute_transform_for).and_return(:the_transform) }

      it "forwards args to create the expected transform" do
        expect(transform).to be :the_transform
        expect(described_class).to have_received(:attribute_transform_for).once.with(:attr)
      end
    end

    context "when initialized with a key config hash" do
      let(:args) { { transform: { key: :key } } }

      before { allow(described_class).to receive(:key_transform_for).and_return(:the_transform) }

      it "forwards args to create the expected transform" do
        expect(transform).to be :the_transform
        expect(described_class).to have_received(:key_transform_for).once.with(:key)
      end
    end

    context "when initialized with a value config hash" do
      let(:args) { { transform: { value: :val } } }

      before { allow(described_class).to receive(:value_transform_for).and_return(:the_transform) }

      it "forwards args to create the expected transform" do
        expect(transform).to be :the_transform
        expect(described_class).to have_received(:value_transform_for).once.with(:val)
      end
    end

    context "when initialized with a Proc" do
      let(:args) { { transform: proc } }
      let(:proc) { instance_double(Proc) }

      it "returns the given proc" do
        expect(proc).to be proc
      end
    end

    context "when transform is valid and the memoize option is supplied" do
      let(:args) { { transform: proc, memoize: memoize } }
      let(:proc) { ->(v) { v.to_s } }
      let(:memoize) { nil }

      context "when memoize is invalid" do
        let(:memoize) { 10 }

        it "raises an ArgumentError during initialization" do
          expect { instance }.to raise_error ArgumentError, "The memoize option must be true, false, or a configuration hash"
        end
      end

      context "when memoize is true" do
        let(:memoize) { true }

        before { allow(described_class::MemoizedTransform).to receive(:new).and_return(:memoized_transform) }

        it "sets a memoized version of the transform" do
          expect(transform).to be :memoized_transform
          expect(described_class::MemoizedTransform).to have_received(:new).once.with(proc)
        end
      end

      context "when memoize is an invalid configuration hash" do
        let(:memoize) { { by: 10 } }

        it "raises an ArgumentError during initialization" do
          expect { instance }.to raise_error ArgumentError, "The :by option of the configuration hash must be callable"
        end
      end

      context "when memoize is a valid configuration hash" do
        let(:memoize) { { by: ->(v) { v.to_s } } }

        before { allow(described_class::MemoizedTransform).to receive(:new).and_return(:memoized_transform) }

        it "sets a configured, memoized version of the transform" do
          expect(transform).to be :memoized_transform
          expect(described_class::MemoizedTransform).to have_received(:new).once.with(proc, memoize)
        end
      end
    end
  end
end
