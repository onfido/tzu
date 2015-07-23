# Tzu

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

If you use `invalid!` while catching an exception, you can pass it the exception as an argument.
The exception's `#message` value will be passed along the the outcome.

```ruby
class MyRescueCommand
  include Tzu

  def call(params)
    take_action(params)
  rescue StandardError => e
    invalid!(e)
  end
end
```

```ruby
outcome = MyRescueCommand.run!(params_that_cause_error) #=> Tzu::Invalid: 'You did not do it'
```

Note that if you pass a string to `invalid!`, it will coerce the result into a hash of the form:

```
{ errors: 'Error String' }
```

Any other type will simply be passed through.

## Passing Blocks

You can also pass a block to Tzu commands.

Successful commands will execute the `success` block, and invalid commands will execute the `invalid` block.
This is particularly useful in controllers.

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

## Request objects

You can define a request object for your command using the `#given` method.

```ruby
class MyValidatedCommand
  include Tzu, Tzu::Validation

  given MyRequestObject

  def call(request)
    "Name: #{request.name}, Age: #{request.age}"
  end
end
```

Request objects must implement an initializer that accepts the command's parameters hash.

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

  given MyRequestObject

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
