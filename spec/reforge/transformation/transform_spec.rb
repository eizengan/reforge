# frozen_string_literal: true

RSpec.describe Reforge::Transformation::Transform do
  subject(:instance) { described_class.new(transform, **opts) }

  let(:transform) { { key: :key } }
  let(:opts) { {} }

  context "when initialized with an invalid transform" do
    let(:transform) { 5 }

    it "raises an ArgumentError during initialization" do
      expect { instance }.to raise_error ArgumentError, "The transform must be callable"
    end
  end

  context "when initialized with an invalid configuration hash" do
    let(:transform) { { valyoo: 5 } }

    it "raises an ArgumentError during initialization" do
      expect { instance }.to raise_error ArgumentError, "The transform configuration hash must define exactly one transform type"
    end
  end

  context "when the memoize option is supplied" do
    let(:transform) { { attribute: :to_sym } }
    let(:opts) { { memoize: { by: memoize } } }
    let(:memoize) { ->(s) { s[0] } }

    before { allow(described_class::Memo).to receive(:from).and_call_original }

    it "creates the expected Memo" do
      instance
      expect(described_class::Memo).to have_received(:from).with(by: memoize)
    end

    it "returns and memoizes the value by the memo key" do
      expect(instance.call("foo")).to be :foo
      expect(instance.call("faz")).to be :foo
    end

    context "when the transform is called on a source with a corresponding memo entry" do
      before { instance.call("foo") }

      it "returns the value at the corresponding memo key" do
        expect(instance.call("faz")).to be :foo
      end

      it "does not change at the corresponding memo key" do
        expect(instance.call("faz")).to be :foo
        expect(instance.call("foo")).to be :foo
      end
    end
  end

  describe "#call" do
    subject(:call) { instance.call(source) }

    let(:source) { { foo: :bar } }

    before do
      allow(instance.transform).to receive(:call).and_call_original
    end

    context "when initialized with an attribute config hash" do
      let(:transform) { { attribute: :size } }

      it "delegates to the transform to return the expected attribute from the source" do
        expect(call).to be 1
        expect(instance.transform).to have_received(:call).once.with(source)
      end

      # TRICKY: we need to avoid RSpecs memoization habits to make this test work, so we can't use let or subject to
      # simplify this
      it "does not modify the config hash" do
        hash = { attribute: :size }
        expect { described_class.new(hash, **opts) }.not_to(change { hash })
      end

      context "when called on a nil value" do
        let(:source) { nil }

        it "raises a NoMethodError when delegating to the transform" do
          expect { call }.to raise_error NoMethodError, "undefined method `size' for nil:NilClass"
          expect(instance.transform).to have_received(:call).once.with(source)
        end

        context "when 'propogate_nil: true' was supplied as an option" do
          let(:transform) { { attribute: :size, propogate_nil: true } }

          it "delegates to the transform and returns nil" do
            expect(call).to be_nil
            expect(instance.transform).to have_received(:call).once.with(source)
          end
        end
      end

      context "when initialized with multiple attributes" do
        let(:transform) { { attribute: %i[size to_s] } }

        it "delegates to the transform to return the source's value at the given attributes" do
          expect(call).to eq "1"
          expect(instance.transform).to have_received(:call).once.with(source)
        end

        context "when called on a nil value" do
          let(:source) { nil }

          it "raises a NoMethodError when delegating to the transform" do
            expect { call }.to raise_error NoMethodError, "undefined method `size' for nil:NilClass"
            expect(instance.transform).to have_received(:call).once.with(source)
          end

          context "when 'propogate_nil: true' was supplied as an option" do
            let(:transform) { { attribute: %i[size to_s], propogate_nil: true } }

            it "delegates to the transform and returns nil" do
              expect(call).to be_nil
              expect(instance.transform).to have_received(:call).once.with(source)
            end
          end
        end
      end
    end

    context "when initialized with a key config hash" do
      let(:transform) { { key: :foo } }

      it "delegates to the transform to return the source's value at the given key" do
        expect(call).to be :bar
        expect(instance.transform).to have_received(:call).once.with(source)
      end

      # TRICKY: we need to avoid RSpecs memoization habits to make this test work, so we can't use let or subject to
      # simplify this
      it "does not modify the config hash" do
        hash = { key: :foo }
        expect { described_class.new(hash, **opts) }.not_to(change { hash })
      end

      context "when called on a nil value" do
        let(:source) { nil }

        it "raises a NoMethodError when delegating to the transform" do
          expect { call }.to raise_error NoMethodError, "undefined method `[]' for nil:NilClass"
          expect(instance.transform).to have_received(:call).once.with(source)
        end

        context "when 'propogate_nil: true' was supplied as an option" do
          let(:transform) { { key: :foo, propogate_nil: true } }

          it "delegates to the transform and returns nil" do
            expect(call).to be_nil
            expect(instance.transform).to have_received(:call).once.with(source)
          end
        end
      end

      context "when initialized with multiple keys" do
        let(:source) { { foo: { bar: :baz } } }
        let(:transform) { { key: %i[foo bar] } }

        it "delegates to the transform to return the source's value at the given keys" do
          expect(call).to be :baz
          expect(instance.transform).to have_received(:call).once.with(source)
        end

        context "when called on a nil value" do
          let(:source) { nil }

          it "raises a NoMethodError when delegating to the transform" do
            expect { call }.to raise_error NoMethodError, "undefined method `[]' for nil:NilClass"
            expect(instance.transform).to have_received(:call).once.with(source)
          end

          context "when 'propogate_nil: true' was supplied as an option" do
            let(:transform) { { key: %i[foo bar], propogate_nil: true } }

            it "delegates to the transform and returns nil" do
              expect(call).to be_nil
              expect(instance.transform).to have_received(:call).once.with(source)
            end
          end
        end
      end
    end

    context "when initialized with a value config hash" do
      let(:transform) { { value: :val } }

      it "delegates to the transform to return the expected value" do
        expect(call).to be :val
        expect(instance.transform).to have_received(:call).once.with(source)
      end

      # TRICKY: we need to avoid RSpecs memoization habits to make this test work, so we can't use let or subject to
      # simplify this
      it "does not modify the config hash" do
        hash = { value: :val }
        expect { described_class.new(hash, **opts) }.not_to(change { hash })
      end
    end

    context "when initialized with a Proc" do
      let(:transform) { ->(s) { s.transform_values(&:to_s) } }

      it "delegates to the transform" do
        expect(call).to eq({ foo: "bar" })
        expect(instance.transform).to have_received(:call).once.with(source)
      end
    end
  end
end
