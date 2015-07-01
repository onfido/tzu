require 'spec_helper'

describe Tzu do

  context 'command fails' do
    subject do
      Class.new do
        include Tzu

        def call(params)
          fail! :something
        end
      end
    end

    it 'returns failure' do
      result = subject.run(nil)
      expect(result).to have_attributes(success: false, type: :something)
    end
  end

  context 'command succeeds' do
    subject do
      Class.new do
        include Tzu

        def call(params)
          1234
        end
      end
    end

    it 'returns result' do
      result = subject.run(nil)
      expect(result).to have_attributes(success: true, result: 1234)
    end
  end

end
