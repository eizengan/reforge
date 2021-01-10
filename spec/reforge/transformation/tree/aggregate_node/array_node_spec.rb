# frozen_string_literal: true

RSpec.describe Reforge::Transformation::Tree::AggregateNode::ArrayNode do
  subject(:instance) { described_class.new }

  describe "#children" do
    subject(:children) { instance.children }

    it "initializes to an empty array" do
      expect(children).to eq []
    end
  end

  describe "#call" do
    subject(:call) { instance.call(:source) }

    let(:children) { [child1, nil, child2] }
    let(:child1) { instance_double(described_class) }
    let(:child2) { instance_double(described_class) }

    before do
      allow(instance).to receive(:children).and_return(children)
      allow(child1).to receive(:call).and_return(:result1)
      allow(child2).to receive(:call).and_return(:result2)
    end

    it "delegates to its children to create the expected array" do
      expect(call).to eq [:result1, nil, :result2]
      expect(child1).to have_received(:call).with(:source)
      expect(child2).to have_received(:call).with(:source)
    end
  end
end
