require 'spec_helper'

describe Tzu::Validation do

  context 'params define valid? method' do
    subject do
      Class.new do
        include Tzu
        include Tzu::Validation
      end
    end

    let(:errors) { [1, 2, 3] }
    let(:params) { spy(errors: errors, valid?: false) }

    it 'valid? method is called' do
      subject.run(params)
      expect(params).to have_received(:valid?)
    end

    it 'returns validation result' do
      result = subject.run(params)
      expect(result).to have_attributes(success: false, type: :validation, result: errors)
    end
  end

  context 'command defines valid? method' do
    subject do
      Class.new do
        include Tzu
        include Tzu::Validation

        def valid?(params)
          Tzu::ValidationResult.new(false, [])
        end
      end
    end

    it 'returns validation result' do
      result = subject.run(nil)
      expect(result).to have_attributes(success: false, type: :validation)
    end
  end

  context 'error message is string' do
    let(:str) { 'error_message' }
    subject { Tzu::Invalid.new(str) }

    context 'invoked directly' do
      it 'has string as #message' do
        expect(subject.message).to eq str
      end

      it '#errors converts sting to hash' do
        expect(subject.errors).to eq(errors: str)
      end
    end

    context 'rescued' do
      subject do
        Class.new do
          include Tzu
          include Tzu::Validation

          def call(params)
            raise StandardError.new(params)
          rescue StandardError => e
            invalid! e
          end
        end
      end

      describe '#run' do
        it 'returns error hash as result' do
          outcome = subject.run(str)
          expect(outcome.result).to eq(errors: str)
        end
      end

      describe '#run!' do
        it 'has string as #message' do
          expect { subject.run!(str) }.to raise_error Tzu::Invalid, str
        end

        it 'has string as #errors' do
          begin
            subject.run!(str)
            expect(false).to be true # Should never reach this
          rescue Tzu::Invalid => e
            expect(e.errors).to eq(errors: str)
          end
        end
      end
    end
  end
end
