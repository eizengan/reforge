# frozen_string_literal: true

RSpec.describe Reforge::Tree::AggregateNode::HashNode do
  subject(:instance) { described_class.new }

  describe "#children" do
    subject(:children) { instance.children }

    it "initializes to an empty hash" do
      expect(children).to eq({})
    end
  end

  describe "#reforge" do
    subject(:reforge) { instance.reforge(:source) }

    let(:children) { { child_1: child_1, child_2: child_2 } }
    let(:child_1) { instance_double(described_class) }
    let(:child_2) { instance_double(described_class) }

    before do
      allow(instance).to receive(:children).and_return(children)
      allow(child_1).to receive(:reforge).and_return(:result_1)
      allow(child_2).to receive(:reforge).and_return(:result_2)
    end

    it "delegates to its children to create the expected hash" do
      expect(reforge).to eq(child_1: :result_1, child_2: :result_2)
      expect(child_1).to have_received(:reforge).with(:source)
      expect(child_2).to have_received(:reforge).with(:source)
    end
  end
end
