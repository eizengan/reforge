# frozen_string_literal: true

RSpec.describe Reforge::Tree do
  subject(:instance) { described_class.new }

  describe "#attach_extractor" do
    subject(:attach_extractor) { instance.attach_extractor(:foo, 0, extractor) }

    let(:extractor) { Reforge::Extractor.new(type: :value, args: [0]) }

    it "adds the expected nodes to the tree" do
      expect { attach_extractor }.to change { instance.root }.from(nil).to an_instance_of(Reforge::Tree::AggregateNode)
      expect(instance.root[:foo]).to be_an_instance_of(Reforge::Tree::AggregateNode)
      expect(instance.root[:foo][0]).to be_an_instance_of(Reforge::Tree::ExtractorNode)
      expect(instance.root[:foo][0].extractor).to be extractor
    end

    context "when nodes already exist in the tree" do
      let(:other_extractor) { Reforge::Extractor.new(type: :value, args: [0]) }

      before { instance.attach_extractor(:bar, other_extractor) }

      it "adds the expected nodes to those already in the tree" do
        expect { attach_extractor }.not_to change(instance, :root)
        expect(instance.root[:bar]).to be_an_instance_of(Reforge::Tree::ExtractorNode)
        expect(instance.root[:bar].extractor).to be other_extractor

        expect(instance.root[:foo]).to be_an_instance_of(Reforge::Tree::AggregateNode)
        expect(instance.root[:foo][0]).to be_an_instance_of(Reforge::Tree::ExtractorNode)
        expect(instance.root[:foo][0].extractor).to be extractor
      end

      context "when the path is incompatible with the key_type of the existing nodes" do
        subject(:attach_extractor) { instance.attach_extractor("foo", extractor) }

        # TODO: this error is raised by the node without knowledge of the surrounding context. The error should be
        # made context-sensitive so that the problem is more obvious
        it "raises an ArgumentError" do
          expect { attach_extractor }.to raise_error ArgumentError, "The key must be a Symbol"
        end
      end
    end

    context "when the path consists of only an extractor" do
      subject(:attach_extractor) { instance.attach_extractor(extractor) }

      it "adds the expected node to the tree" do
        expect { attach_extractor }.to change { instance.root }.from(nil).to an_instance_of(Reforge::Tree::ExtractorNode)
        expect(instance.root.extractor).to be extractor
      end

      context "when nodes already exist in the tree" do
        before { instance.attach_extractor(:foo, 0, extractor) }

        it "raises a PathRedefinitionError" do
          expect { attach_extractor }.to raise_error Reforge::Tree::PathRedefinitionError, "The root has already been defined"
        end
      end
    end

    context "when path does not end with an extractor" do
      subject(:attach_extractor) { instance.attach_extractor(:foo, nil) }

      it "raises an ArgumentError" do
        expect { attach_extractor }.to raise_error ArgumentError, "The path must end with a Reforge::Extractor"
      end
    end

    context "when the path has invalid parts" do
      subject(:attach_extractor) { instance.attach_extractor(:foo, nil, extractor) }

      it "raises a PathPartError" do
        expect { attach_extractor }.to raise_error ArgumentError, "The path includes '' which has unknown key type NilClass"
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

      instance.attach_extractor(:foo, 0, extractor_1)
      instance.attach_extractor(:foo, 2, extractor_2)
      instance.attach_extractor(:bar, extractor_3)
      instance.attach_extractor(:baz, :faz, extractor_4)
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
