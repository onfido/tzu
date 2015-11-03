# Tzu [![Build Status](https://travis-ci.org/onfido/tzu.svg)](https://travis-ci.org/onfido/tzu)

Tzu provides a simple interface for writing classes that encapsulate a single command.

**Commands should:**

- Do exactly one thing (Single Responsibility Priciple)
- Be self-documenting
- Be testable
- Be easy to mock and stub

**Benefits**

- File and class names say what your code *actually does*, making onboarding and debugging a much simpler process.
- Minimize the instances of persistence logic throughout the application
- The Rails 'where do I put...?' question is solved. Models, Controllers, Workers and even Rake Tasks become slim.
- Maintain all of the benefits of Object Oriented programming while executing a procedural action, or Sequence of procedural actions.

**Documentation**

- [Usage](#usage)
- [Validation](#validation)
- [Passing Blocks](#passing-blocks)
- [Hooks](#hooks)
- [Request Objects](#request-objects)

**Sequences**
- [Configure](#configure)
- [Execute](#execute)
- [Integrating Non Tzu Classes](#integrating-non-tzu-classes)
- [Hooks for Sequences](#hooks-for-sequences)
- [Mocking and Stubbing](#mocking-and-stubbing)

## Usage

Tzu commands must include Tzu and implement a `#call` method.

```ruby
class MyCommand
  include Tzu

  def call(params)
    "My Command Response - #{params.message}"
  end
end
```

Tzu exposes `#run` at the class level, and returns an Outcome object.
The Outcome's `result` will be the return value of the command's `#call` method.

```ruby
outcome = MyCommand.run(message: 'Hello!')
#=> #<Tzu::Outcome @success=false, @result='My Command Response - Hello!'>

outcome.success? #=> true
outcome.failure? #=> false
outcome.result #=> 'My Command Response - Hello!'
```

## Validation

Tzu also provides an `invalid!` method that allows you to elegantly escape execution.

```ruby
class MyCommand
  include Tzu

  def call(params)
    invalid!('You did not do it') unless params[:message] == 'I did it!'
    "My Command Response - #{params[:message]}"
  end
end
```

When invoking Tzu with `#run`, `invalid!` will return an invalid Outcome.

```ruby
outcome = MyCommand.run(message: 'Hello!')
outcome.success? #=> false
outcome.failure? #=> true
outcome.type #=> :validation
outcome.result #=> { errors: 'You did not do it' }
```

When invoking Tzu with `#run!`, `invalid!` will throw a Tzu::Invalid error.

```ruby
outcome = MyCommand.run!(message: 'Hello!') #=> Tzu::Invalid: 'You did not do it'
```

If you use `invalid!` while catching an exception, you can pass the exception as an argument.
The exception's `#message` value will be passed along to the outcome.

```ruby
class MyRescueCommand
  include Tzu

  def call(params)
    raise StandardError.new('You did not do it')
  rescue StandardError => e
    invalid!(e)
  end
end
```

```ruby
outcome = MyRescueCommand.run!(params_that_cause_error)
#=> Tzu::Invalid: 'You did not do it'
```

Note that if you pass a string to `invalid!`, it will coerce the result into a hash of the form:

```ruby
# Invoking:
invalid!('Error String')

# Translates to:
{ errors: 'Error String' }
```

Any other type will simply be passed through.

## Passing Blocks

You can also pass a block to Tzu commands.

Successful commands will execute the `success` block, and invalid commands will execute the `invalid` block.
This is particularly useful in controllers:

```ruby
MyCommand.run(message: params[:message]) do
  success do |result|
    render(json: {message: result}.to_json, status: 200)
  end

  invalid do |errors|
    render(json: errors.to_json, status: 422)
  end
end
```

## Hooks

Tzu commands accept `before`, `after`, and `around` hooks.
All hooks are executed in the order they are declared.

```ruby
class MyCommand
  include Tzu

  around do |command|
    puts 'Begin Around 1'
    command.call
    puts 'End Around 1'
  end

  around do |command|
    puts 'Begin Around 2'
    command.call
    puts 'End Around 2'
  end

  before { puts 'Before 1' }
  before { puts 'Before 2' }

  after { puts 'After 1' }
  after { puts 'After 2' }

  def call(params)
    puts "My Command Response - #{params[:message]}"
  end
end

MyCommand.run(message: 'Hello!')

#=> Begin Around 1
#=> Begin Around 2
#=> Before 1
#=> Before 2
#=> My Command Response - Hello!
#=> After 1
#=> After 2
#=> End Around 2
#=> End Around 1
```

## Request Objects

You can define a request object for your command using the `#request_object` method.

```ruby
class MyValidatedCommand
  include Tzu, Tzu::Validation

  request_object MyRequestObject

  def call(request)
    "Name: #{request.name}, Age: #{request.age}"
  end
end
```

Request objects must implement an initializer that accepts the command's parameters.

If you wish to validate your parameters, the Request object must implement `#valid?` and `#errors`.

```ruby
class MySimpleRequestObject
  def initialize(params)
    @params = params
  end

  def valid?
    # Validate Parameters
  end

  def errors
    # Why aren't I valid?
  end
end
```

A very useful combination for request objects is Virtus.model and ActiveModel::Validations.

ActiveModel::Validations exposes all of the validators used on Rails models.
Virtus.model validates the types of your inputs, and also makes them available via dot notation.

```ruby
class MyRequestObject
  include Virtus.model
  include ActiveModel::Validations

  validates :name, :age, presence: :true

  attribute :name, String
  attribute :age, Integer
end
```

If your request object is invalid, Tzu will return an invalid outcome before reaching the `#call` method.
The invalid Outcome's result is populated by the request object's `#errors` method.

```ruby
class MyValidatedCommand
  include Tzu, Tzu::Validation

  request_object MyRequestObject

  def call(request)
    "Name: #{request.name}, Age: #{request.age}"
  end
end

outcome = MyValidatedCommand.run(name: 'Charles')
#=> #<Command::Outcome @success=false, @result={:age=>["can't be blank"]}, @type=:validation>

outcome.success? #=> false
outcome.type? #=> :validation
outcome.result #=> {:age=>["can't be blank"]}
```

# Execute Commands in Sequence

## Configure

Tzu provides a declarative way of encapsulating sequential command execution.

Consider the following commands:

```ruby
class SayMyName
  include Tzu

  def call(params)
    "Hello, #{params[:name]}"
  end
end

class MakeMeSoundImportant
  include Tzu

  def call(params)
    "#{params[:boring_message]}! You are the most important citizen of #{params[:country]}!"
  end
end
```

Tzu::Sequence provides a DSL for executing them in sequence:

```ruby
class ProclaimMyImportance
  include Tzu::Sequence

  step SayMyName do
    receives do |params|
      { name: params[:name] }
    end
  end

  step MakeMeSoundImportant do
    receives do |params, prior_results|
      {
        boring_message: prior_results[:say_my_name],
        country: params[:country]
      }
    end
  end
end
```

Each command to be executed is defined as the first argument of `step`.
The `receives` method inside the `step` block allows you to mutate the parameters being passed into the command.
It is passed both the original parameters and a hash containing the results of prior commands.

By default, the keys of the `prior_results` hash are demodulized/underscored/symbolized command names.
You can define your own keys using the `as` method.

```ruby
step SayMyName do
  as :first_command_key
  receives do |params|
    { name: params[:name] }
  end
end
```

If you don't need to mutate the parameters for the command, simply omit `receives`.

```ruby
step SayMyName
```

## Execute

By default, Sequences return the result of the final command.

```ruby
outcome = ProclaimMyImportance.run(name: 'Jessica', country: 'Azerbaijan')
outcome.success? #=> true
outcome.result #=> 'Hello, Jessica! You are the most important citizen of Azerbaijan!'
```

Sequences can be configured to return the entire `prior_results` hash by passing `:take_all` to the `result` method.

```ruby
class ProclaimMyImportance
  include Tzu::Sequence

  step SayMyName do
    receives do |params|
      { name: params[:name] }
    end
  end

  step MakeMeSoundImportant do
    receives do |params, prior_results|
      {
        boring_message: prior_results[:say_my_name],
        country: params[:country]
      }
    end
  end

  result :take_all
end

outcome = ProclaimMyImportance.run(name: 'Jessica', country: 'Azerbaijan')
outcome.result
#=> { say_my_name: 'Hello, Jessica', make_me_sound_important: 'Hello, Jessica! You are the most important citizen of Azerbaijan!' }
```

You can also mutate the result into any form you choose by passing a block to `result`.

```ruby
class ProclaimMyImportance
  include Tzu::Sequence

  step SayMyName do
    receives do |params|
      { name: params[:name] }
    end
  end

  step MakeMeSoundImportant do
    as :final_command
    receives do |params, prior_results|
      {
        boring_message: prior_results[:say_my_name],
        country: params[:country]
      }
    end
  end

  result do |params, prior_results|
    {
      name: params[:name],
      original_message: prior_results[:say_my_name],
      message: "BULLETIN: #{prior_results[:final_command]}"
    }
  end
end

outcome = ProclaimMyImportance.run(name: 'Jessica', country: 'Azerbaijan')
outcome.result
#=> { name: 'Jessica', original_message: 'Hello, Jessica', message: 'BULLETIN: Hello, Jessica! You are the most important citizen of Azerbaijan!' }
```

## Integrating Non Tzu Classes

Sometimes there is a need to combine non-Tzu classes with Tzu classes in a sequence.

As an example, let's say I wanted to query a record, update it, and pass the updated record to a Tzu command.
To do this, I'll use the [Get](https://github.com/onfido/get) and [Tradesman](https://github.com/onfido/tradesman/) libraries.

When invoked on its own, Get looks like this:
```ruby
Get::UserByName.run(name)
```

Tradesman Update looks like this:
```ruby
Tradesman::UpdateUser.go(user_id, update_params)
```

The integration of Get into `Tzu::Sequence` is easy, as it only expects one parameter, and it's invoked with `#run`.
Tradesman is more complicated; it expects two parameters - a User ID and a hash to update that record with - and it's invoked with `#go`.

Tradesman offers the `invoke_with` and `receives_many` arguments to deal with these differences.

`invoke_with` is self-explanatory, and defaults to `#run`.

The `receives_many` block must return an array, which will be passed as a splat to the `invoke_with` method.
```ruby
class NonTzuSequence
  include Tzu::Sequence

  step Get::UserByName do
    receives do |params|
      params[:name]
    end
  end

  step Tradesman::UpdateUser do
    invoke_with :go

    receives_many do |params, prior_results|
      [
        prior_results[:user_by_name].id,
        params[:update_params]
      ]
    end
  end

  step SayMyName do
    receives do |params, prior_results|
      prior_results[:update_user].name
    end
  end
end

outcome = NonTzuSequence.run(name: 'Blake', update_params: { name: 'Morgan' })
outcome.result #=> 'Hello, Morgan'
```

You can pass multiple parameters to `Tzu::Sequence` instead of a parameters hash, just make sure you add the correct amount of arguments to your `receives` and `receives_many` blocks.

```ruby
class NonTzuSequence
  include Tzu::Sequence

  step Get::UserByName do
    receives do |name, update_params|
      name
    end
  end

  step Tradesman::UpdateUser do
    invoke_with :go

    receives_many do |name, update_params, prior_results|
      [prior_results[:user_by_name].id, update_params]
    end
  end

  step SayMyName do
    receives do |name, update_params, prior_results|
      prior_results[:update_user].name
    end
  end
end

outcome = NonTzuSequence.run('Blake', { name: 'Morgan' })
outcome.result #=> 'Hello, Morgan'
```

## Hooks for Sequences

Tzu sequences have the same `before`, `after`, and `around` hooks available in Tzu commands.
This is particularly useful for wrapping multiple commands in a transaction.

```ruby
class ProclaimMyImportance
  include Tzu::Sequence

  around do |sequence|
    ActiveRecord::Base.transaction do
      sequence.call
    end
  end

  step SayMyName do
    receives do |params|
      { name: params[:name] }
    end
  end

  step MakeMeSoundImportant do
    receives do |params, prior_results|
      {
        boring_message: prior_results[:say_my_name],
        country: params[:country]
      }
    end
  end
end
```

## Mocking and Stubbing

Tzu has a specialized (and well-documented) gem for mocking/stubbing, [TzuMock](https://github.com/onfido/tzu_mock).
