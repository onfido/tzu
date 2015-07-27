require 'spec_helper'

describe Tzu::Step do
  let(:dummy_mutator) { proc { 'Dummy!' } }

  context '#name' do
    context 'when name is symbol' do
      let(:step) { Tzu::Step.new(:step_name) }

      it 'returns name' do
        expect(step.name).to eq :step_name
      end
    end

    context 'when name is a class' do
      let(:step) { Tzu::Step.new(StandardError) }
      let(:outcome) { ControlledOutcome.run(result: :success) }

      it 'returns underscored name' do
        expect(step.name).to eq :standard_error
      end
    end
  end
end
