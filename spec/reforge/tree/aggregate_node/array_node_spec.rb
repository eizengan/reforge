# frozen_string_literal: true

RSpec.describe Reforge::Tree::AggregateNode::ArrayNode do
  subject(:instance) { described_class.new }

  describe ".validate_key!" do
    subject(:validate_key!) { described_class.validate_key!(key) }

    let(:key) { nil }

    context "when the key is an Integer" do
      let(:key) { 123 }

      it "does not raise" do
        expect { validate_key! }.not_to raise_error
      end
    end

    context "when the key is not an Integer" do
      let(:key) { "hi" }

      it "raises an ArgumentError" do
        expect { validate_key! }.to raise_error ArgumentError, "The key must be an Integer"
      end
    end
  end

  describe "#children" do
    subject(:children) { instance.children }

    it "initializes to an empty array" do
      expect(children).to eq []
    end
  end

  describe "#reforge" do
    subject(:reforge) { instance.reforge(:source) }

    let(:children) { [child_1, nil, child_2] }
    let(:child_1) { instance_double(described_class) }
    let(:child_2) { instance_double(described_class) }

    before do
      allow(instance).to receive(:children).and_return(children)
      allow(child_1).to receive(:reforge).and_return(:result_1)
      allow(child_2).to receive(:reforge).and_return(:result_2)
    end

    it "delegates to its children to create the expected array" do
      expect(reforge).to eq [:result_1, nil, :result_2]
      expect(child_1).to have_received(:reforge).with(:source)
      expect(child_2).to have_received(:reforge).with(:source)
    end
  end
end
