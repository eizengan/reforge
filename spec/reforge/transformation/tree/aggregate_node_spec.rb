# frozen_string_literal: true

RSpec.describe Reforge::Transformation::Tree::AggregateNode do
  subject(:instance) { described_class.new(key_type) }

  let(:key_type) { Symbol }

  describe "#implementation" do
    subject(:implementation) { instance.implementation }

    context "when the key_type is Integer" do
      let(:key_type) { Integer }

      before { allow(described_class::ArrayNode).to receive(:new).and_call_original }

      it "creates an ArrayNode implementation" do
        expect(implementation).to be_an_instance_of described_class::ArrayNode
        expect(described_class::ArrayNode).to have_received(:new).once
      end
    end

    context "when the key_type is Symbol" do
      let(:key_type) { Symbol }

      before { allow(described_class::HashNode).to receive(:new).and_call_original }

      it "creates a HashNode implementation" do
        expect(implementation).to be_an_instance_of described_class::HashNode
        expect(described_class::HashNode).to have_received(:new).once
      end
    end

    context "when the key_type is String" do
      let(:key_type) { String }

      before { allow(described_class::HashNode).to receive(:new).and_call_original }

      it "creates a HashNode implementation" do
        expect(implementation).to be_an_instance_of described_class::HashNode
        expect(described_class::HashNode).to have_received(:new).once
      end
    end

    context "when initialized with an unknown key_type" do
      let(:key_type) { Range }

      it "raises an ArgumentError error during initialization" do
        expect { instance }.to raise_error ArgumentError, "No AggregateNode implementation for key_type Range"
      end
    end
  end

  describe "#call" do
    subject(:call) { instance.call(:source) }

    before { allow(instance.implementation).to receive(:call).and_return(:result) }

    it "delegates to its implementation" do
      expect(call).to eq :result
      expect(instance.implementation).to have_received(:call).once.with(:source)
    end
  end

  describe "#[]=" do
    subject(:set_element) { instance[:key] = node }

    let(:key_type) { Symbol }
    let(:node) { described_class.new(Integer) }

    it "sets the child at the given key to the given node" do
      expect { set_element }.to change { instance[:key] }.from(nil).to(node)
    end

    context "when the node is not an AggregateNode or TransformNode" do
      let(:node) { :not_a_node }

      it "raises an ArgumentError" do
        expect { set_element }.to raise_error ArgumentError, "The node must be an AggregateNode or TransformNode"
      end
    end

    context "when the key does not match the node's key_type" do
      let(:key_type) { String }

      it "raises an ArgumentError" do
        expect { set_element }.to raise_error ArgumentError, "Expected :key at node path [:key] to be of String type"
      end
    end

    context "when a node already exists at the given key" do
      before { instance[:key] = described_class.new(Symbol) }

      it "raises an NodeRedefinitionError" do
        expect { set_element }.to raise_error Reforge::Transformation::Tree::NodeRedefinitionError, "Node already exists at [:key]"
      end
    end
  end

  describe "#[]" do
    subject(:get_element) { instance[:key] }

    let(:node) { described_class.new(Symbol) }

    before { instance[:key] = node }

    it "returns the child at the given key" do
      expect(get_element).to eq node
    end

    context "when the key does not match the node's key_type" do
      subject(:get_element) { instance[0] }

      it "raises an ArgumentError" do
        expect { get_element }.to raise_error ArgumentError, "Expected 0 at node path [0] to be of Symbol type"
      end
    end
  end
end
