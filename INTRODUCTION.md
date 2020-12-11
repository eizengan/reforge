# Introduction

This guide outlines the basic knowledge required to use Reforge in a project. Navigation links for the guide are provided below for your convenience.

## Table of Contents

- [Installation](#installation)
- [Getting Started](#getting-started)
- [Terminology](#terminology)
- [The Transformation DSL](#the-transformation-dsl)
- [Defining Paths](#defining-paths)
- [Defining Transforms](#defining-transforms)
  - [Attribute Configuration Hashes](#attribute-configuration-hashes)
  - [Key Configuration Hashes](#key-configuration-hashes)
  - [Nil Propogation](#nil-propogation)
  - [Value Configuration Hashes](#value-configuration-hashes)
- [Memoizing Transform Results](#memoizing-transform-results)
  - [Memo Lifetime](#memo-lifetime)
  - [Simple Memoization](#simple-memoization)
  - [Calculating A Transform Only Once](#calculating-a-transform-only-once)
  - [Custom Memoization](#custom-memoization)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reforge'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reforge

## Terminology

**Transformation** : The most crucial class provided by Reforge. Provides a simple DSL to define one or more *Pathed Transforms*, and uses them to convert a *Source* into a *Result*.

**Pathed Transform** : A pairing of a *Transform* and a *Path*. Describes both how to obtain a value from a *Source* and a location to place it within the *Result*.

**Transform** : A description of how to obtain a single, transformed value from a *Source*.

**Path** : A description of a location within a *Result*. Typically a Symbol/String key when the *Result* is a Hash, or an Integer index when the *Result* is an Array.

**Source** : An object which a *Transformation* can convert into a *Result*. Can be any object, but all the *Transformation's* constituent *Transforms* must succeed when processing it.

**Result** : The object created by a *Transformation* from a *Source* by aggregating the output of all its *Pathed Transforms*.

## Getting Started

The following example illustrates how to create a Transformation and transform your data:

```ruby
require "reforge"
require "date"

def expensive_method
  puts "expensive_method was called, but only once!"
  sleep(10)
  "hello world"
end

class ExampleTransform < Reforge::Transformation
  extract :date, from: ->(source) { Date.parse(source[:timestamp]) }
  extract :amount, from: { key: :usd }
  extract :expensive_result, from: -> { expensive_method }, memoize: :first
end

sources = [
  { timestamp: "2019-01-01", usd: 1.23 },
  { timestamp: "2019-01-10", usd: 2.46 },
  { timestamp: "2019-10-01", usd: 3.69 }
]
results = ExampleTransform.call(*sources)
# expensive_method was called, but only once!
# => [{:date=>#<Date: 2019-01-01 ...>, :amount=>1.23, :expensive_result=>"hello world"},
#     {:date=>#<Date: 2019-01-10 ...>, :amount=>2.46, :expensive_result=>"hello world"},
#     {:date=>#<Date: 2019-10-01 ...>, :amount=>3.69, :expensive_result=>"hello world"}]
```

You can glean the following from the above example:

- Transformations are created by inheriting the `Reforge::Transformation` class
- The Result of a Transformation is described in parts by using the `.extract` DSL method
- The `.extract` DSL method takes a Path to determine where in the Result to place transformed Source data
- The `.extract` DSL method takes a `from:` keyword argument to determine a Transform to perform on the Source data
- Transforms of Source data can be defined by a proc or derived from a special configuration hash
- The `.extract` DSL method takes an optional `memoize:` keyword argument which can sometimes be used to avoid repeating expensive Transforms

These are all described in greater detail below, and are linked in the [Table of Contents](#table-of-contents).

## The Transformation DSL

Inheriting from the `Reforge::Transformation` class grants access to the DSL methods outlined in the example below:

```ruby
class DSLExamples < Reforge::Transformation
  extract path_definition, from: transform_definition, memoize: memoize_options
  transform transform_definition, into: path_definition, memoize: memoize_options
end
```

The `.extract` and `.transform` methods are used to define Pathed Transforms, and cause identical results when given the same arguments (as above). You may use whichever method better suits your use case, although this documentation prefers `.extract`. The path_definition must [define a valid Path](#defining-paths). The transform_definition must [define a valid Transform](#defining-transforms). The memoize parameter is optional, and when included is used to [avoid repeating expensive Transforms](#memoizing-transform-results).

Errors resulting from improper usage of the DSL are not raised immediately. Instead they are deferred until the Transformation containing the improper DSL calls is instantiated or otherwise used. This ensures an application using Reforge will not break outside contexts where improper DSL usage could adversely affect its behavior.

## Defining Paths

Paths are used by Reforge to determine where in the Result to place transformed Source data. They are also used to determine what form the Result will take - a path of `:key` or `"key"` will result in a Hash, and `0` in an Array. A Path with Array type will nest the value using the same logic. The following examples assume that data placed by `path` is `"data"`:

```ruby
path = :foo        # result = { foo: "data" }
path = "foo"       # result = { "foo" => "data" }
path = 0           # result = ["data"]
path = [:foo, 0]   # result = { foo: ["data"] }
path = %i[foo bar] # result = { foo: { bar: "data" } }
```

## Defining Transforms

Transforms are used by Reforge to determine how to obtain a single, transformed value from a Source. A Transform can be a Proc taking one argument (the Source) or no arguments. For some simple Transforms a Configuration Hash can be used instead.

### Transform Configuration Hashes

#### Key Configuration Hashes

If the data you need exists in a nesting of Hash- or Array-like objects, then you can use a key configuration hash to obtain it. These paired Transforms will produce the same results:
```ruby
transform = ->(source) { source[:foo] }
transform = { key: :foo }

nested_transform = ->(source) { source[:foo][1] }
nested_transform = { key: [:foo, 1] }
```

#### Attribute Configuration Hashes

Similarly if the data you need lies at the end of a series of attribute calls, then you can use an attribute configuration hash to obtain it. These paired Transforms will produce the same results:
```ruby
transform = ->(source) { source.size }
transform = { attribute: :size }

nested_transform = ->(source) { source.size.digits }
nested_transform = { attribute: %i[size digits] }

```

#### Nil Propogation

The Transforms made by key and attribute configuration hashes will most likely fail if they hit a nil value. To avoid this, you may pass the option `propogate_nil: true`. These Transforms will produce the same results:
```ruby
transform = ->(source) { source&.size&.digits }
transform = { attribute: %i[size digits], propogate_nil: true }
```

#### Value Configuration Hashes

Sometimes the data you need to add is independent of the Source and will not change. In such cases you can use a value configuration hash. These Transforms will produce the same results:
```ruby
transform = -> { 1_234_567 }
transform = { value: 1_234_567 }
```

## Memoizing Transform Results

There may be occasions where your Transforms are expensive in terms of time or resources. The initial cost of these Transforms may be unavoidable, but by memoizing the Transform results you can avoid incurring it when the Transform is repeated. By specifying what criteria qualify as "repitition", you can tailor memoization perfectly to your use case.

### Memo Lifetime

Memoized results will last as long as the Transformation that uses them. For calls directly against the class this is the duration of the call, and for calls against a Transformation instance this is equal the lifetime of that instance:

```ruby
class ExampleTransformation < Reforge::Transformation
  extract :expensive_result, from: -> { expensive_method }, memoize: :true
end

# The memo from this call lasts only for the duration of that call - future calls are unaffected
ExampleTransformation.call(*sources)


# A Transformation instance keeps its memo between calls...
transformation = ExampleTransformation.new
transform.call(*sources)
# ...so since all the sources have already been memoized by the call above, the call below only ever uses the
# memoized results
transform.call(*sources)
```

### Simple Memoization

Basic memoization is performed by providing the `memoize: true` option to the DSL's Transform creation methods. This style of memoization stores the Transform result by its source, and future calls will use this result instead of recalculating it:

```ruby
def expensive_method(i)
  puts "expensive_method was called!"
  sleep(10)
  "result for #{i}"
end

class ExampleTransform < Reforge::Transformation
  extract :expensive_result, from: ->(i) { expensive_method(i) }, memoize: :true
end

sources = [1, 1]
results = ExampleTransform.call(*sources)
# expensive_method was called!
# => [{:expensive_result=>"result for 1"},
#     {:expensive_result=>"result for 1"}]

sources = [1, 2, 2]
results = ExampleTransform.call(*sources)
# expensive_method was called!
# expensive_method was called!
# => [{:expensive_result=>"result for 1"},
#     {:expensive_result=>"result for 2"},
#     {:expensive_result=>"result for 2"}]
```

### Calculating A Transform Only Once

You may find cases where you only need to calculate the results of a Transform once. As an example, perhaps to add a timestamp to the resulting object. This can be done by supplying the DSL's Transform creation methods with the `memoize: :first` option. This stores the first value for the first Transform call, and will continue using it for all future calls regardless of the Source:

```ruby
def current_time
  puts "calculating current time"
  Time.now
end

class ExampleTransform < Reforge::Transformation
  extract :timestamp, from: -> { current_time }, memoize: :first
end

sources = [*1..5]
results = ExampleTransform.call(*sources)
# calculating current time
# => [{:timestamp=>2020-12-10 18:29:52 -0500},
#     {:timestamp=>2020-12-10 18:29:52 -0500},
#     {:timestamp=>2020-12-10 18:29:52 -0500},
#     {:timestamp=>2020-12-10 18:29:52 -0500},
#     {:timestamp=>2020-12-10 18:29:52 -0500}]
```

### Custom Memoization

You may create your own memoization schemes in cases where memoization is required but none of the built-in schemes will work. As an example, perhaps an attribute of the source contains a substring which corresponds to an ID in your database; in other words: the transform result should be memoized by that substring, not by the source itself. This can be accomplished by providing a configuration hash to the memoize option, such as `memoize: { by: ->(s) { s.id_attr[0..10] } }`. This configuration hash must contain the `:by` key, which must contain a [valid tranform definition](#defining-transforms) - either a Proc or a configuration hash. When the transform specified at the `:by` key results in a value for which the transform was already calculated, then the memoized transform will return the stored result:

```ruby
def find_customer(customer_id)
  puts "finding customer with id='#{id}'"
  Customer.find(customer_id)
end

class ExampleTransform < Reforge::Transformation
  extract :customer,
          from: ->(source) { find_customer(source[:purchase_order].purchase_order.split("-").first) },
          memoize: { by: ->(source) { source[:purchase_order].split("-").first } }
end

sources = [
  { purchase_order: "123-2020-12-01" },
  { purchase_order: "123-2020-12-02" },
  { purchase_order: "456-2020-12-01" }
]
results = ExampleTransform.call(*sources)
# finding customer with id='123'
# finding customer with id='456'
# => [{:customer=>#<Retailer id: 123, ...>,
#     {:customer=>#<Retailer id: 123, ...>,
#     {:customer=>#<Retailer id: 456, ...>]
```
