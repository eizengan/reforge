# frozen_string_literal: true

RSpec.describe Reforge::Transformation::Tree do
  subject(:instance) { described_class.new }

  describe "#attach_transform" do
    subject(:attach_transform) { instance.attach_transform(:foo, 0, transform) }

    let(:transform) { Reforge::Transformation::Transform.new(value: 0) }

    it "adds the expected nodes to the tree" do
      expect { attach_transform }.to change { instance.root }.from(nil).to an_instance_of(described_class::AggregateNode)
      expect(instance.root[:foo]).to be_an_instance_of(described_class::AggregateNode)
      expect(instance.root[:foo][0]).to be_an_instance_of(described_class::TransformNode)
      expect(instance.root[:foo][0].transform).to be transform
    end

    context "when nodes already exist in the tree" do
      let(:other_transform) { Reforge::Transformation::Transform.new(value: 0) }

      before { instance.attach_transform(:bar, other_transform) }

      it "adds the expected nodes to those already in the tree" do
        expect { attach_transform }.not_to change(instance, :root)
        expect(instance.root[:bar]).to be_an_instance_of(described_class::TransformNode)
        expect(instance.root[:bar].transform).to be other_transform

        expect(instance.root[:foo]).to be_an_instance_of(described_class::AggregateNode)
        expect(instance.root[:foo][0]).to be_an_instance_of(described_class::TransformNode)
        expect(instance.root[:foo][0].transform).to be transform
      end

      context "when the path is incompatible with the key_type of the existing nodes" do
        before { instance.attach_transform(:foo, 0, other_transform) }

        subject(:attach_transform) { instance.attach_transform(:foo, "bar", transform) }

        it "raises an ArgumentError" do
          expect { attach_transform }.to raise_error ArgumentError, 'Expected "bar" at node path [:foo, "bar"] to be of Integer type'
        end
      end

      context "when the transform would take the spot of an existing node" do
        subject(:attach_transform) { instance.attach_transform(:foo, "bar", transform) }

        before { instance.attach_transform(:foo, "bar", transform) }

        it "raises a NodeRedefinitionError" do
          expect { attach_transform }.to raise_error described_class::NodeRedefinitionError, 'Node already exists at [:foo, "bar"]'
        end
      end
    end

    context "when the path consists of only a transform" do
      subject(:attach_transform) { instance.attach_transform(transform) }

      it "adds the expected node to the tree" do
        expect { attach_transform }.to change { instance.root }.from(nil).to an_instance_of(described_class::TransformNode)
        expect(instance.root.transform).to be transform
      end

      context "when nodes already exist in the tree" do
        before { instance.attach_transform(:foo, 0, transform) }

        it "raises a PathRedefinitionError" do
          expect { attach_transform }.to raise_error described_class::NodeRedefinitionError, "The root node has already been defined"
        end
      end
    end

    context "when path does not end with a transform" do
      subject(:attach_transform) { instance.attach_transform(:foo, nil) }

      it "raises an ArgumentError" do
        expect { attach_transform }.to raise_error ArgumentError, "The path must end with a Transform"
      end
    end

    context "when the path has invalid parts" do
      subject(:attach_transform) { instance.attach_transform(:foo, nil, transform) }

      it "raises a PathPartError" do
        expect { attach_transform }.to raise_error ArgumentError, "The path includes '' which has unknown key type NilClass"
      end
    end
  end

  describe "#call" do
    subject(:call) { instance.call(:source) }

    let(:transform1) { Reforge::Transformation::Transform.new(value: :result1) }
    let(:transform2) { Reforge::Transformation::Transform.new(value: :result2) }
    let(:transform3) { Reforge::Transformation::Transform.new(value: :result3) }
    let(:transform4) { Reforge::Transformation::Transform.new(value: :result4) }

    before do
      allow(transform1).to receive(:call).and_call_original
      allow(transform2).to receive(:call).and_call_original
      allow(transform3).to receive(:call).and_call_original
      allow(transform4).to receive(:call).and_call_original

      instance.attach_transform(:foo, 0, transform1)
      instance.attach_transform(:foo, 2, transform2)
      instance.attach_transform(:bar, transform3)
      instance.attach_transform(:baz, :faz, transform4)
    end

    it "uses the tree's nodes to transform the data" do
      expect(call).to eq(
        foo: [:result1, nil, :result2],
        bar: :result3,
        baz: { faz: :result4 }
      )
      expect(transform1).to have_received(:call).once.with(:source)
      expect(transform2).to have_received(:call).once.with(:source)
      expect(transform3).to have_received(:call).once.with(:source)
      expect(transform4).to have_received(:call).once.with(:source)
    end
  end
end
