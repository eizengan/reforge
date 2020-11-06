# frozen_string_literal: true

RSpec.describe Reforge do
  # TODO: better way to clean class instance vars between tests to avoid pollution
  def clear_instance_variable(object, instance_variable)
    object.remove_instance_variable(instance_variable) if object.instance_variable_defined?(instance_variable)
  end

  around do |example|
    clear_instance_variable(described_class, :@configuration)
    example.run
    clear_instance_variable(described_class, :@configuration)
  end

  describe ".configure" do
    before { allow(described_class).to receive(:configuration).and_return(:configuration) }

    it { expect { |b| described_class.configure(&b) }.to yield_with_args :configuration }
  end

  describe ".configuration" do
    subject(:configuration) { described_class.configuration }

    context "when no configuration currently exists" do
      before do
        described_class.configuration = nil
        allow(described_class::Configuration).to receive(:new).and_return(:configuration)
      end

      it "creates and returns a new configuration" do
        expect(configuration).to be :configuration
        expect(described_class::Configuration).to have_received(:new)
      end
    end

    context "when a configuration already exists" do
      before { described_class.configuration = :configuration }

      it "returns the existing configuration" do
        expect(configuration).to be :configuration
      end
    end
  end

  describe ".configuration=" do
    it "sets the configuration" do
      expect { described_class.configuration = :configuration }.to change(described_class, :configuration).to(:configuration)
    end
  end
end
