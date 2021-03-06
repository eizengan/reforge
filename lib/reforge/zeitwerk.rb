# frozen_string_literal: true

require "zeitwerk"

# TRICKY: Zeitwerk::Loader.for_gem would work if this were in lib/reforge.rb, but we have initialization here to
# keep loader logic consolidated. We need to reconstruct the work the work done by that method, and to do so correctly
# from any location we need to establish a path to our root module and its home directory
reforge_path = "#{__dir__}/../reforge.rb"
reforge_dir = File.dirname(File.realpath(reforge_path))

loader = Zeitwerk::Loader.new
loader.tag = File.basename(reforge_path)
loader.inflector = Zeitwerk::Inflector.new
loader.inflector.inflect("dsl" => "DSL")
loader.do_not_eager_load("#{__dir__}/zeitwerk.rb")
loader.push_dir(reforge_dir)
loader.setup
