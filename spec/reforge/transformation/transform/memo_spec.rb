# frozen_string_literal: true

RSpec.describe Reforge::Transformation::Transform::Memo do
  subject(:instance) { described_class.new(key_transform) }

  let(:key_transform) { described_class::IDENTITY_TRANSFORM }

  describe ".from" do
    subject(:from) { described_class.from(memoize) }

    let(:memo) { instance_double(described_class) }

    before { allow(described_class).to receive(:new).and_return(memo) }

    context "when memoize is invalid" do
      let(:memoize) { 10 }

      it "raises an ArgumentError" do
        expect { from }.to raise_error ArgumentError, "The memoize option should be true, :first, or a valid configuration hash"
      end
    end

    context "when memoize is a configuration hash" do
      let(:memoize) { { by: :arg } }

      it "returns the expected Memo" do
        expect(from).to be memo
        expect(described_class).to have_received(:new).with(:arg)
      end

      context "when the configuration hash is invalid" do
        let(:memoize) { { by: nil } }

        before { allow(described_class).to receive(:new).and_call_original }

        it "raises an ArgumentError" do
          expect { from }.to raise_error ArgumentError, "The memoize option should be true, :first, or a valid configuration hash"
        end
      end
    end

    context "when memoize is :first" do
      let(:memoize) { :first }

      it "returns the expected Memo" do
        expect(from).to be memo
        expect(described_class).to have_received(:new).with(described_class::CONSTANT_TRANSFORM)
      end
    end

    context "when memoize is true" do
      let(:memoize) { :first }

      it "returns the expected Memo" do
        expect(from).to be memo
        expect(described_class).to have_received(:new).with(described_class::IDENTITY_TRANSFORM)
      end
    end
  end

  describe ".new" do
    let(:key_transform) { { key: :foo } }

    before { allow(Reforge::Transformation::Transform).to receive(:new) }

    it "delegates to Transform to create the key_transform" do
      instance
      expect(Reforge::Transformation::Transform).to have_received(:new).with(key_transform)
    end
  end

  describe "#[]" do
    subject(:get_element) { instance["100"] }

    let(:key_transform) { ->(s) { s[0] } }

    before { instance["10"] = 10 }

    it "sends the key through the key transform and returns the result" do
      expect(get_element).to eq 10
    end
  end

  describe "#[]=" do
    subject(:set_element) { instance["100"] = 100 }

    let(:key_transform) { ->(s) { s[0] } }

    before { instance["10"] = 10 }

    it "sends the key through the key transform and sets the result" do
      set_element
      expect(instance["100"]).to eq 100
      expect(instance["10"]).to eq 100
    end
  end
end
