require 'spec_helper'

describe Tzu::Organizer do
  let(:params) { [1, 2, 3] }
  let(:commands) { [spy(run!: :step1, command_name: :step1), spy(run!: :step2, command_name: :step2)] }

  let(:organized) do
    organized = Class.new do
      include Tzu::Organizer

      def initialize(commands)
        commands.each { |s| add_step(s) }
      end
    end

    organized
  end

  context 'when organizer is called' do

    it 'calls each step' do
      organized.run(params, commands)
      commands.each { |s| expect(s).to have_received(:run!).with(params) }
    end

    it 'collates result of steps' do
      result = organized.run(params, commands)
      expect(result.result.step1).to eq(:step1)
      expect(result.result.step2).to eq(:step2)
    end
  end

  context 'when organizer defines parse' do
    before do
      organized.class_eval do
        def parse(result)
          12345
        end
      end
    end

    it 'it parses results from commands' do
      result = organized.run(params, commands)
      expect(result).to have_attributes(success: true, result: 12345)
    end
  end

end