# frozen_string_literal: true

RSpec.describe Reforge::Tree do
  subject(:instance) { described_class.new }

  describe "#attach_transform" do
    subject(:attach_transform) { instance.attach_transform(:foo, 0, transform) }

    let(:transform) { Reforge::Transform.new(transform: { value: 0 }) }

    it "adds the expected nodes to the tree" do
      expect { attach_transform }.to change { instance.root }.from(nil).to an_instance_of(Reforge::Tree::AggregateNode)
      expect(instance.root[:foo]).to be_an_instance_of(Reforge::Tree::AggregateNode)
      expect(instance.root[:foo][0]).to be_an_instance_of(Reforge::Tree::TransformNode)
      expect(instance.root[:foo][0].transform).to be transform
    end

    context "when nodes already exist in the tree" do
      let(:other_transform) { Reforge::Transform.new(transform: { value: 0 }) }

      before { instance.attach_transform(:bar, other_transform) }

      it "adds the expected nodes to those already in the tree" do
        expect { attach_transform }.not_to change(instance, :root)
        expect(instance.root[:bar]).to be_an_instance_of(Reforge::Tree::TransformNode)
        expect(instance.root[:bar].transform).to be other_transform

        expect(instance.root[:foo]).to be_an_instance_of(Reforge::Tree::AggregateNode)
        expect(instance.root[:foo][0]).to be_an_instance_of(Reforge::Tree::TransformNode)
        expect(instance.root[:foo][0].transform).to be transform
      end

      context "when the path is incompatible with the key_type of the existing nodes" do
        subject(:attach_transform) { instance.attach_transform("foo", transform) }

        # TODO: this error is raised by the node without knowledge of the surrounding context. The error should be
        # made context-sensitive so that the problem is more obvious
        it "raises an ArgumentError" do
          expect { attach_transform }.to raise_error ArgumentError, "The key must be a Symbol"
        end
      end

      context "when the transform would take the spot of an existing node" do
        subject(:attach_transform) { instance.attach_transform(:bar, transform) }

        # TODO: this error is raised by the node without knowledge of the surrounding context. The error should be
        # made context-sensitive so that the problem is more obvious
        it "raises a NodeRedefinitionError" do
          expect { attach_transform }.to raise_error Reforge::Tree::NodeRedefinitionError, "A node already exists at key 'bar'"
        end
      end
    end

    context "when the path consists of only a transform" do
      subject(:attach_transform) { instance.attach_transform(transform) }

      it "adds the expected node to the tree" do
        expect { attach_transform }.to change { instance.root }.from(nil).to an_instance_of(Reforge::Tree::TransformNode)
        expect(instance.root.transform).to be transform
      end

      context "when nodes already exist in the tree" do
        before { instance.attach_transform(:foo, 0, transform) }

        it "raises a PathRedefinitionError" do
          expect { attach_transform }.to raise_error Reforge::Tree::NodeRedefinitionError, "The root node has already been defined"
        end
      end
    end

    context "when path does not end with a transform" do
      subject(:attach_transform) { instance.attach_transform(:foo, nil) }

      it "raises an ArgumentError" do
        expect { attach_transform }.to raise_error ArgumentError, "The path must end with a Reforge::Transform"
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

    let(:transform_1) { Reforge::Transform.new(transform: { value: :result_1 }) }
    let(:transform_2) { Reforge::Transform.new(transform: { value: :result_2 }) }
    let(:transform_3) { Reforge::Transform.new(transform: { value: :result_3 }) }
    let(:transform_4) { Reforge::Transform.new(transform: { value: :result_4 }) }

    before do
      allow(transform_1).to receive(:call).and_call_original
      allow(transform_2).to receive(:call).and_call_original
      allow(transform_3).to receive(:call).and_call_original
      allow(transform_4).to receive(:call).and_call_original

      instance.attach_transform(:foo, 0, transform_1)
      instance.attach_transform(:foo, 2, transform_2)
      instance.attach_transform(:bar, transform_3)
      instance.attach_transform(:baz, :faz, transform_4)
    end

    it "uses the tree's nodes to transform the data" do
      expect(call).to eq(
        foo: [:result_1, nil, :result_2],
        bar: :result_3,
        baz: { faz: :result_4 }
      )
      expect(transform_1).to have_received(:call).once.with(:source)
      expect(transform_2).to have_received(:call).once.with(:source)
      expect(transform_3).to have_received(:call).once.with(:source)
      expect(transform_4).to have_received(:call).once.with(:source)
    end
  end
end
