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

  context '#receives' do
    context 'when splat_mutator is already defined' do
      let(:step) { Tzu::Step.new(:step_name) }

      before do
        step.receives_many do |variable|
          [1, 2, 3]
        end
      end

      it 'throws error' do
        expect { step.receives { |var| 'foo'} } .to raise_error(Tzu::InvalidSequence)
      end
    end
  end

  context '#receives_many' do
    context 'when single_mutator is already defined' do
      let(:step) { Tzu::Step.new(:step_name) }

      before do
        step.receives do |var|
          'hello'
        end
      end

      it 'throws error' do
        expect { step.receives_many { |var| [1, 2, 3] } } .to raise_error(Tzu::InvalidSequence)
      end
    end
  end
end
