# frozen_string_literal: true

RSpec.describe Reforge::Transform do
  subject(:instance) { described_class.new(**args) }

  let(:args) { { transform: { key: :key } } }

  context "when initialized with an invalid transform" do
    let(:args) { { transform: 5 } }

    it "raises an ArgumentError during initialization" do
      expect { instance }.to raise_error ArgumentError, "The transform must be callable or a configuration hash"
    end
  end

  context "when the memoize option is supplied" do
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
        expect(instance.transform).to be :memoized_transform
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
        expect(instance.transform).to be :memoized_transform
        expect(described_class::MemoizedTransform).to have_received(:new).once.with(proc, memoize)
      end
    end
  end

  describe "#call" do
    subject(:call) { instance.call(source) }

    let(:source) { { foo: :bar } }

    before do
      allow(instance.transform).to receive(:call).and_call_original
    end

    context "when initialized with an attribute config hash" do
      let(:args) { { transform: { attribute: :size } } }

      it "delegates to the transform to return the expected attribute from the source" do
        expect(call).to be 1
        expect(instance.transform).to have_received(:call).once.with(source)
      end

      context "when initialized with multiple attributes" do
        let(:args) { { transform: { attribute: %i[size to_s] } } }

        it "delegates to the transform to return the source's value at the given attributes" do
          expect(call).to eq "1"
          expect(instance.transform).to have_received(:call).once.with(source)
        end
      end
    end

    context "when initialized with a key config hash" do
      let(:args) { { transform: { key: :foo } } }

      it "delegates to the transform to return the source's value at the given key" do
        expect(call).to be :bar
        expect(instance.transform).to have_received(:call).once.with(source)
      end

      context "when initialized with multiple keys" do
        let(:source) { { foo: { bar: :baz } } }
        let(:args) { { transform: { key: %i[foo bar] } } }

        it "delegates to the transform to return the source's value at the given keys" do
          expect(call).to be :baz
          expect(instance.transform).to have_received(:call).once.with(source)
        end
      end
    end

    context "when initialized with a value config hash" do
      let(:args) { { transform: { value: :val } } }

      it "delegates to the transform to return the expected value" do
        expect(call).to be :val
        expect(instance.transform).to have_received(:call).once.with(source)
      end
    end

    context "when initialized with a Proc" do
      let(:args) { { transform: proc } }
      let(:proc) { ->(s) { s.transform_values(&:to_s) } }

      it "delegates to the transform" do
        expect(call).to eq({ foo: "bar" })
        expect(instance.transform).to have_received(:call).once.with(source)
      end
    end
  end
end
