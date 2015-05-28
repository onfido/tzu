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
end