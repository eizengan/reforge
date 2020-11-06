# frozen_string_literal: true

require "reforge/zeitwerk"

module Reforge
  def self.configure
    yield configuration if block_given?
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=(configuration)
    @configuration = configuration
  end
end
