# frozen_string_literal: true

RSpec.describe Reforge::Tree::AggregateNode do
  subject(:instance) { described_class.new(type) }

  let(:type) { :hash }

  describe "#implementation" do
    subject(:implementation) { instance.implementation }

    context "when the type is :array" do
      let(:type) { :array }

      before { allow(described_class::ArrayNode).to receive(:new).and_call_original }

      it "creates a ArrayNode implementation" do
        expect(implementation).to be_an_instance_of described_class::ArrayNode
        expect(described_class::ArrayNode).to have_received(:new).once
      end
    end

    context "when the type is :hash" do
      let(:type) { :hash }

      before { allow(described_class::HashNode).to receive(:new).and_call_original }

      it "creates a HashNode implementation" do
        expect(implementation).to be_an_instance_of described_class::HashNode
        expect(described_class::HashNode).to have_received(:new).once
      end
    end

    context "when initialized with an unknown type" do
      let(:type) { :not_a_known_type }

      it "raises an ExtractorTypeError error during initialization" do
        expect { instance }.to raise_error described_class::AggregateNodeTypeError, "No AggregateNode implementation for type 'not_a_known_type'"
      end
    end
  end

  describe "#reforge" do
    subject(:reforge) { instance.reforge(:source) }

    before { allow(instance.implementation).to receive(:reforge).and_return(:result) }

    it "delegates to its implementation" do
      expect(reforge).to eq :result
      expect(instance.implementation).to have_received(:reforge).once.with(:source)
    end
  end

  describe "#add_child" do
    subject(:add_child) { instance.add_child(:key, node) }

    let(:node) { described_class.new(:hash) }

    it "sets the child at the given key to the given node" do
      expect { add_child }.to change { instance.implementation.children[:key] }.from(nil).to(node)
    end

    context "when the node is not a AggregatNode or ExtractorNode" do
      let(:node) { :not_a_node }

      it "raises an ArgumentError" do
        expect { add_child }.to raise_error ArgumentError, "The node must be a Reforge::AggregateNode or Reforge::ExtractorNode"
      end
    end

    context "when the implementation rejects the key" do
      before { allow(instance.implementation.class).to receive(:validate_key!).and_raise(ArgumentError, "Error message") }

      it "raises an ArgumentError" do
        expect { add_child }.to raise_error ArgumentError, "Error message"
      end
    end
  end

  describe "#child_at" do
    subject(:child_at) { instance.child_at(:key) }

    let(:node) { described_class.new(:hash) }

    before { instance.add_child(:key, node) }

    it "returns the child at the given key" do
      expect(child_at).to eq node
    end

    context "when the implementation rejects the key" do
      before { allow(instance.implementation.class).to receive(:validate_key!).and_raise(ArgumentError, "Error message") }

      it "raises an ArgumentError" do
        expect { child_at }.to raise_error ArgumentError, "Error message"
      end
    end
  end
end
