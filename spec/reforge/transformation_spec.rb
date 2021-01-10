# frozen_string_literal: true

RSpec.describe Reforge::Transformation do
  subject(:instance) { subclass.new }

  let(:subclass) { Class.new(described_class) }

  describe "DSL" do
    describe ".extract" do
      context "when a transform hash is provided" do
        subject(:extract) do
          subclass.extract %i[foo bar], from: { key: 0 }, memoize: { by: { attribute: :size } }
        end

        it "adds the expected transform definition" do
          expect { extract }.to change(subclass.transform_definitions, :size).from(0).to(1)
          expect(subclass.transform_definitions.first).to eq(
            path: %i[foo bar],
            transform: { key: 0 },
            memoize: { by: { attribute: :size } }
          )
        end

        context "when the transform has no path" do
          subject(:extract) do
            subclass.extract from: { key: 0 }, memoize: { by: { attribute: :size } }
          end

          it "does not raise an error" do
            expect { extract }.not_to raise_error
          end

          it "adds the expected transform definition" do
            expect { extract }.to change(subclass.transform_definitions, :size).from(0).to(1)
            expect(subclass.transform_definitions.first).to eq(
              transform: { key: 0 },
              memoize: { by: { attribute: :size } }
            )
          end
        end
      end

      context "when a transform proc is provided" do
        subject(:extract) do
          subclass.extract %i[foo bar], from: transform_proc, memoize: { by: { attribute: :size } }
        end

        let(:transform_proc) { ->(s) { s[0] } }

        it "adds the expected transform definition" do
          expect { extract }.to change(subclass.transform_definitions, :size).from(0).to(1)
          expect(subclass.transform_definitions.first).to eq(
            path: %i[foo bar],
            transform: transform_proc,
            memoize: { by: { attribute: :size } }
          )
        end

        context "when the transform has no path" do
          subject(:extract) do
            subclass.extract from: transform_proc, memoize: { by: { attribute: :size } }
          end

          it "does not raise an error" do
            expect { extract }.not_to raise_error
          end

          it "adds the expected transform definition" do
            expect { extract }.to change(subclass.transform_definitions, :size).from(0).to(1)
            expect(subclass.transform_definitions.first).to eq(
              transform: transform_proc,
              memoize: { by: { attribute: :size } }
            )
          end
        end
      end
    end

    describe ".transform" do
      context "when a transform hash is provided" do
        subject(:transform) do
          subclass.transform key: 0, into: %i[foo bar], memoize: { by: { attribute: :size } }
        end

        it "adds the expected transform definition" do
          expect { transform }.to change(subclass.transform_definitions, :size).from(0).to(1)
          expect(subclass.transform_definitions.first).to eq(
            path: %i[foo bar],
            transform: { key: 0 },
            memoize: { by: { attribute: :size } }
          )
        end

        context "when the transform has no path" do
          subject(:extract) do
            subclass.transform key: 0, memoize: { by: { attribute: :size } }
          end

          it "does not raise an error" do
            expect { extract }.not_to raise_error
          end

          it "adds the expected transform definition" do
            expect { extract }.to change(subclass.transform_definitions, :size).from(0).to(1)
            expect(subclass.transform_definitions.first).to eq(
              transform: { key: 0 },
              memoize: { by: { attribute: :size } }
            )
          end
        end
      end

      context "when a transform proc is provided" do
        subject(:transform) do
          subclass.transform transform_proc, into: %i[foo bar], memoize: { by: { attribute: :size } }
        end
        let(:transform_proc) { ->(s) { s[0] } }

        it "adds the expected transform definition" do
          expect { transform }.to change(subclass.transform_definitions, :size).from(0).to(1)
          expect(subclass.transform_definitions.first).to eq(
            path: %i[foo bar],
            transform: transform_proc,
            memoize: { by: { attribute: :size } }
          )
        end

        context "when the transform has no path" do
          subject(:extract) do
            subclass.transform transform_proc, memoize: { by: { attribute: :size } }
          end

          it "does not raise an error" do
            expect { extract }.not_to raise_error
          end

          it "adds the expected transform definition" do
            expect { extract }.to change(subclass.transform_definitions, :size).from(0).to(1)
            expect(subclass.transform_definitions.first).to eq(
              transform: transform_proc,
              memoize: { by: { attribute: :size } }
            )
          end
        end
      end
    end

    describe ".create_tree" do
      subject(:create_tree) { subclass.create_tree }

      let(:foo_bar_transform) { instance_double(described_class::Transform) }
      let(:baz_transform) { instance_double(described_class::Transform) }
      let(:qux_0_transform) { instance_double(described_class::Transform) }
      let(:tree) { instance_double(described_class::Tree) }

      before do
        allow(described_class::Transform).to receive(:new).with({ key: 0 }, memoize: { by: { attribute: :size } }).and_return(foo_bar_transform)
        allow(described_class::Transform).to receive(:new).with({ key: 1 }, memoize: true).and_return(baz_transform)
        allow(described_class::Transform).to receive(:new).with({ key: 3 }, { memoize: nil }).and_return(qux_0_transform)

        allow(described_class::Tree).to receive(:new).and_return(tree)
        allow(tree).to receive(:attach_transform)

        allow(subclass).to receive(:transform_definitions).and_return [
          { path: %i[foo bar], transform: { key: 0 }, memoize: { by: { attribute: :size } } },
          { path: %i[baz], transform: { key: 1 }, memoize: true },
          { path: [:qux, 0], transform: { key: 3 } }
        ]
      end

      it "creates the tree described by the transform_definitions", aggregate_failures: true do
        expect(create_tree).to be tree

        expect(described_class::Transform).to have_received(:new).once.with({ key: 0 }, { memoize: { by: { attribute: :size } } })
        expect(described_class::Transform).to have_received(:new).once.with({ key: 1 }, { memoize: true })
        expect(described_class::Transform).to have_received(:new).once.with({ key: 3 }, { memoize: nil })

        expect(tree).to have_received(:attach_transform).once.with(:foo, :bar, foo_bar_transform)
        expect(tree).to have_received(:attach_transform).once.with(:baz, baz_transform)
        expect(tree).to have_received(:attach_transform).once.with(:qux, 0, qux_0_transform)
      end
    end
  end

  describe ".call" do
    subject(:call) { subclass.call(:source) }

    before do
      allow(subclass).to receive(:new).and_return(instance)
      allow(instance).to receive(:call).and_return(:result)
    end

    it "creates and delegates to an instance" do
      expect(call).to be :result
      expect(instance).to have_received(:call).once.with(:source)
    end
  end

  describe "#call" do
    subject(:call) { instance.call(:source) }

    let(:tree) { instance_double(described_class::Tree) }

    before do
      allow(subclass).to receive(:create_tree).and_return(tree)
      allow(tree).to receive(:call).with(:source).and_return(:result)
    end

    it "delegates to a tree created by the subclass and returns the result" do
      expect(call).to be :result
      expect(subclass).to have_received(:create_tree).once
      expect(tree).to have_received(:call).once.with(:source)
    end

    context "when passed multiple sources" do
      subject(:call) { instance.call(:source, :other_source, :yet_another_source) }

      before do
        allow(tree).to receive(:call).with(:other_source).and_return(:other_result)
        allow(tree).to receive(:call).with(:yet_another_source).and_return(:yet_another_result)
      end

      it "delegates to a tree created by the subclass and returns a result for each source" do
        expect(call).to eq %i[result other_result yet_another_result]
        expect(subclass).to have_received(:create_tree).once
        expect(tree).to have_received(:call).once.with(:source)
        expect(tree).to have_received(:call).once.with(:other_source)
        expect(tree).to have_received(:call).once.with(:yet_another_source)
      end
    end
  end
end
