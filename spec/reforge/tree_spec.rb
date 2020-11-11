# frozen_string_literal: true

RSpec.describe Reforge::Tree do
  subject(:instance) { described_class.new }

  describe "#add_extractor" do
    subject(:add_extractor) { instance.add_extractor(:foo, 0, extractor) }

    let(:extractor) { Reforge::Extractor.new(type: :value, args: [0]) }

    it "adds the expected nodes to the tree" do
      expect { add_extractor }.to change { instance.root }.from(nil).to an_instance_of(Reforge::Tree::AggregateNode)
      expect(instance.root[:foo]).to be_an_instance_of(Reforge::Tree::AggregateNode)
      expect(instance.root[:foo][0]).to be_an_instance_of(Reforge::Tree::ExtractorNode)
    end

    context "when nodes already exist in the tree" do
      before do
        instance.add_extractor(:bar, extractor)
      end

      it "adds the expected nodes to those already in the tree" do
        expect { add_extractor }.not_to change(instance, :root)
        expect(instance.root[:foo]).to be_an_instance_of(Reforge::Tree::AggregateNode)
        expect(instance.root[:foo][0]).to be_an_instance_of(Reforge::Tree::ExtractorNode)
        expect(instance.root[:bar]).to be_an_instance_of(Reforge::Tree::ExtractorNode)
      end
    end

    context "when the extractor is invalid" do
      subject(:add_extractor) { instance.add_extractor(:foo, nil) }

      it "raises an ArgumentError" do
        expect { add_extractor }.to raise_error ArgumentError, "The extractor must be a Reforge::Extractor"
      end
    end

    context "when the path is invalid" do
      subject(:add_extractor) { instance.add_extractor(:foo, nil, extractor) }

      it "raises a PathTypeError" do
        expect { add_extractor }.to raise_error(
          Reforge::Tree::PathTypeError,
          "Path includes an element of type NilClass with no corresponding node type"
        )
      end
    end
  end

  describe "#reforge" do
    subject(:reforge) { instance.reforge(:source) }

    let(:extractor_1) { Reforge::Extractor.new(type: :value, args: [:result_1]) }
    let(:extractor_2) { Reforge::Extractor.new(type: :value, args: [:result_2]) }
    let(:extractor_3) { Reforge::Extractor.new(type: :value, args: [:result_3]) }
    let(:extractor_4) { Reforge::Extractor.new(type: :value, args: [:result_4]) }

    before do
      allow(extractor_1).to receive(:extract_from).and_call_original
      allow(extractor_2).to receive(:extract_from).and_call_original
      allow(extractor_3).to receive(:extract_from).and_call_original
      allow(extractor_4).to receive(:extract_from).and_call_original

      instance.add_extractor(:foo, 0, extractor_1)
      instance.add_extractor(:foo, 2, extractor_2)
      instance.add_extractor(:bar, extractor_3)
      instance.add_extractor(:baz, :faz, extractor_4)
    end

    it "uses the tree's nodes to transform the data" do
      expect(reforge).to eq(
        foo: [:result_1, nil, :result_2],
        bar: :result_3,
        baz: { faz: :result_4 }
      )
      expect(extractor_1).to have_received(:extract_from).once.with(:source)
      expect(extractor_2).to have_received(:extract_from).once.with(:source)
      expect(extractor_3).to have_received(:extract_from).once.with(:source)
      expect(extractor_4).to have_received(:extract_from).once.with(:source)
    end
  end
end
