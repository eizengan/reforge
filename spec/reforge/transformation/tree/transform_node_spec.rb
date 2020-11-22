# frozen_string_literal: true

RSpec.describe Reforge::Transformation::Tree::TransformNode do
  subject(:instance) { described_class.new(transform) }

  let(:transform) { nil }

  context "when no transform is supplied" do
    let(:transform) { nil }

    it "raises during initialization" do
      expect { instance }.to raise_error ArgumentError, "The transform must be a Transform"
    end
  end

  context "when an invalid transform is supplied" do
    let(:transform) { "hello" }

    it "raises during initialization" do
      expect { instance }.to raise_error ArgumentError, "The transform must be a Transform"
    end
  end

  context "when a valid transform is supplied" do
    let(:transform) { instance_double(Reforge::Transformation::Transform) }

    before { allow(transform).to receive(:is_a?).with(Reforge::Transformation::Transform).and_return(true) }

    describe "#call" do
      subject(:call) { instance.call(:source) }

      before { allow(transform).to receive(:call).and_return(:result) }

      it "delegates to the transform" do
        expect(call).to be :result
        expect(transform).to have_received(:call).once.with(:source)
      end
    end
  end
end
