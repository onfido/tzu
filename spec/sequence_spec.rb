require 'spec_helper'

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

class InvalidCommand
  include Tzu

  def call(params)
    invalid!('Who am I? Why am I here?')
  end
end

class MultiStepSimple
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

class MultiStepComplex
  include Tzu::Sequence

  step SayMyName do
    as :first_command
    receives do |params|
      { name: params[:name] }
    end
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
    receives do |params|
      { name: params[:name] }
    end
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

  step SayMyName do
    receives do |params|
      { name: params[:name] }
    end
  end

  step InvalidCommand do
    receives do |params, prior_results|
      { answer: "#{params[:name]}!!! #{prior_results[:say_my_name]}" }
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

describe Tzu::Sequence do
  context '#steps' do
    context MultiStepSimple do
      let(:steps) { MultiStepSimple.steps }

      it 'returns array of Steps' do
        steps.each { |step| expect(step.is_a? Tzu::Step).to be true }
      end

      it 'passes the appropriate klass, name, and param_mutator to each step' do
        say_my_name = steps.first
        expect(say_my_name.klass).to eq SayMyName
        expect(say_my_name.name).to eq :say_my_name
        expect(say_my_name.param_mutator.is_a? Proc).to be true

        make_me_sound_important = steps.last
        expect(make_me_sound_important.klass).to eq MakeMeSoundImportant
        expect(make_me_sound_important.name).to eq :make_me_sound_important
        expect(make_me_sound_important.param_mutator.is_a? Proc).to be true
      end
    end

    context MultiStepComplex do
      let(:steps) { MultiStepComplex.steps }

      it 'returns array of Steps' do
        steps.each { |step| expect(step.is_a? Tzu::Step).to be true }
      end

      it 'passes the appropriate klass, name, and param_mutator to each step' do
        say_my_name = steps.first
        expect(say_my_name.klass).to eq SayMyName
        expect(say_my_name.name).to eq :first_command
        expect(say_my_name.param_mutator.is_a? Proc).to be true

        make_me_sound_important = steps.last
        expect(make_me_sound_important.klass).to eq MakeMeSoundImportant
        expect(make_me_sound_important.name).to eq :final_command
        expect(make_me_sound_important.param_mutator.is_a? Proc).to be true
      end
    end
  end

  context '#run' do
    let(:params) do
      {
        name: 'Jessica',
        country: 'Azerbaijan'
      }
    end

    context MultiStepSimple do
      it 'returns the outcome of the last command' do
        outcome = MultiStepSimple.run(params)
        expect(outcome.result).to eq 'Hello, Jessica! You are the most important citizen of Azerbaijan!'
      end
    end

    context MultiStepComplex do
      it 'returns the outcome of the last command' do
        outcome = MultiStepComplex.run(params)
        results = outcome.result
        expect(results[:first_command]).to eq 'Hello, Jessica'
        expect(results[:final_command]).to eq 'Hello, Jessica! You are the most important citizen of Azerbaijan!'
      end
    end

    context MultiStepProcessResults do
      it 'returns the outcome of the last command' do
        outcome = MultiStepProcessResults.run(params)
        result = outcome.result
        expect(result[:status]).to eq :important
        expect(result[:message]).to eq 'BULLETIN: Hello, Jessica! You are the most important citizen of Azerbaijan!'
      end
    end

    context MultiStepInvalid do
      it 'stops its execution at the invalid command, which it returns' do
        outcome = MultiStepInvalid.run(params)
        expect(outcome.success?).to be false
        expect(outcome.result).to eq(errors: 'Who am I? Why am I here?')
      end
    end
  end
end
