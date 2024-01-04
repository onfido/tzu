# frozen_string_literal: true

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

class ThrowInvalidError
  include Tzu

  def call(params)
    invalid!("Who am I? Why am I here?")
  end
end

class ConstructGreeting
  class << self
    def go(greeting, name)
      "#{greeting}, #{name}"
    end
  end
end

class MultiStepSimple
  include Tzu::Sequence

  step SayMyName do
    receives do |params|
      {name: params[:name]}
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

class MultiStepNonTzu
  include Tzu::Sequence

  step ConstructGreeting do
    as :say_my_name
    invoke_with :go

    receives_many do |greeting, name, country|
      [greeting, name]
    end
  end

  step MakeMeSoundImportant do
    receives do |greeting, name, country, prior_results|
      {
        boring_message: prior_results[:say_my_name],
        country: country
      }
    end
  end
end

class MultiStepComplex
  include Tzu::Sequence

  step SayMyName do
    as :first_command
  end

  step MakeMeSoundImportant do
    as :final_command
    receives do |params, prior_results|
      {
        boring_message: prior_results[:first_command],
        country: params[:country]
      }
    end
  end

  result :take_all
end

class MultiStepProcessResults
  include Tzu::Sequence

  step SayMyName do
    as :first_command
  end

  step MakeMeSoundImportant do
    as :final_command
    receives do |params, prior_results|
      {
        boring_message: prior_results[:first_command],
        country: params[:country]
      }
    end
  end

  result do |params, prior_results|
    {
      status: :important,
      message: "BULLETIN: #{prior_results[:final_command]}"
    }
  end
end

class MultiStepInvalid
  include Tzu::Sequence

  step SayMyName

  step ThrowInvalidError do
    receives do |params, prior_results|
      {answer: "#{params[:name]}!!! #{prior_results[:say_my_name]}"}
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

RSpec.describe Tzu::Sequence do
  describe "#steps" do
    context MultiStepSimple do
      let(:steps) { MultiStepSimple.steps }

      it "returns array of Steps" do
        steps.each { |step| expect(step.is_a?(Tzu::Step)).to be true }
      end

      it "passes the appropriate klass, name, and param_mutators to each step" do
        say_my_name = steps.first
        expect(say_my_name.klass).to eq SayMyName
        expect(say_my_name.name).to eq :say_my_name
        expect(say_my_name.single_mutator.is_a?(Proc)).to be true

        make_me_sound_important = steps.last
        expect(make_me_sound_important.klass).to eq MakeMeSoundImportant
        expect(make_me_sound_important.name).to eq :make_me_sound_important
        expect(make_me_sound_important.single_mutator.is_a?(Proc)).to be true
      end
    end

    context MultiStepComplex do
      let(:steps) { MultiStepComplex.steps }

      it "returns array of Steps" do
        steps.each { |step| expect(step.is_a?(Tzu::Step)).to be true }
      end

      it "passes the appropriate klass, name, and param_mutators to each step" do
        say_my_name = steps.first
        expect(say_my_name.klass).to eq SayMyName
        expect(say_my_name.name).to eq :first_command

        make_me_sound_important = steps.last
        expect(make_me_sound_important.klass).to eq MakeMeSoundImportant
        expect(make_me_sound_important.name).to eq :final_command
        expect(make_me_sound_important.single_mutator.is_a?(Proc)).to be true
      end
    end
  end

  describe "#run" do
    let(:params) do
      {
        name: "Jessica",
        country: "Azerbaijan"
      }
    end

    context MultiStepSimple do
      it "returns the outcome of the last command" do
        outcome = MultiStepSimple.run(params)
        expect(outcome.result).to eq "Hello, Jessica! You are the most important citizen of Azerbaijan!"
      end
    end

    context MultiStepNonTzu do
      it "returns the outcome of the last command" do
        outcome = MultiStepNonTzu.run("Greetings", "Christopher", "Canada")
        expect(outcome.result).to eq "Greetings, Christopher! You are the most important citizen of Canada!"
      end
    end

    context MultiStepComplex do
      it "returns the outcome of the last command" do
        outcome = MultiStepComplex.run(params)
        results = outcome.result
        expect(results[:first_command]).to eq "Hello, Jessica"
        expect(results[:final_command]).to eq "Hello, Jessica! You are the most important citizen of Azerbaijan!"
      end
    end

    context MultiStepProcessResults do
      it "returns the outcome of the last command" do
        outcome = MultiStepProcessResults.run(params)
        result = outcome.result
        expect(result[:status]).to eq :important
        expect(result[:message]).to eq "BULLETIN: Hello, Jessica! You are the most important citizen of Azerbaijan!"
      end
    end

    context MultiStepInvalid do
      it "stops its execution at the invalid command, which it returns" do
        outcome = MultiStepInvalid.run(params)
        expect(outcome.success?).to be false
        expect(outcome.result).to eq(errors: "Who am I? Why am I here?")
      end
    end
  end
end
