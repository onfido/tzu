# frozen_string_literal: true

require "virtus"
require "active_model"

class ControlledOutcome
  include Tzu

  def call(params)
    result = params[:result]
    return 123 if result == :success
    return invalid!("Invalid Message") if result == :invalid
    fail!(:falure_type, "Failure Message") if result == :failure
  end
end

class MyRequestObject
  attr_reader :value, :errors

  def initialize(params)
    @params = params
    @value = params[:value]
    @errors = "Error Message"
  end

  def valid?
    @params[:valid]
  end
end

class VirtusRequestObject
  include Virtus.model
  include ActiveModel::Validations

  validates :name, :age, presence: true

  attribute :name, String
  attribute :age, Integer
end

class ValidatedCommand
  include Tzu

  request_object MyRequestObject

  def call(request)
    request.value
  end
end

class VirtusValidatedCommand
  include Tzu

  request_object VirtusRequestObject

  def call(request)
    "Name: #{request.name}, Age: #{request.age}"
  end
end

RSpec.describe Tzu do
  describe "#run" do
    context "when command succeeds" do
      let(:outcome) { ControlledOutcome.run(result: :success) }

      it "correctly returns sets pass/fail flags" do
        expect(outcome.success?).to be true
        expect(outcome.failure?).to be false
      end

      it "returns result" do
        expect(outcome.result).to eq(123)
      end
    end

    context "when command is invalid" do
      let(:outcome) { ControlledOutcome.run(result: :invalid) }

      it "correctly returns sets pass/fail flags" do
        expect(outcome.success?).to be false
        expect(outcome.failure?).to be true
      end

      it "returns error string as errors hash" do
        expect(outcome.result).to eq(errors: "Invalid Message")
      end

      it "sets type to validation" do
        expect(outcome.type).to eq(:validation)
      end
    end

    context "when command fails" do
      let(:outcome) { ControlledOutcome.run(result: :failure) }

      it "correctly returns sets pass/fail flags" do
        expect(outcome.success?).to be false
        expect(outcome.failure?).to be true
      end

      it "returns error string as errors hash" do
        expect(outcome.result).to eq(errors: "Failure Message")
      end

      it "sets type to falure_type" do
        expect(outcome.type).to eq(:falure_type)
      end
    end
  end

  describe "#run with block" do
    let(:success_spy) { spy("success") }
    let(:invalid_spy) { spy("invalid") }
    let(:failure_spy) { spy("failure") }

    before do
      ControlledOutcome.run(result: result) do
        success { |_| success_spy.call }
        invalid { |_| invalid_spy.call }
        failure { |_| failure_spy.call }
      end
    end

    context "when command succeeds" do
      let(:result) { :success }

      it "executes success block" do
        expect(success_spy).to have_received(:call)
      end
    end

    context "when command is invalid" do
      let(:result) { :invalid }

      it "executes invalid block" do
        expect(invalid_spy).to have_received(:call)
      end
    end

    context "when command fails" do
      let(:result) { :failure }

      it "executes failure block" do
        expect(failure_spy).to have_received(:call)
      end
    end
  end

  describe "#run with request object" do
    context "when request is valid" do
      let(:outcome) { ValidatedCommand.run(value: 1111, valid: true) }

      it "executes successfully" do
        expect(outcome.success?).to be true
      end

      it "returns value" do
        expect(outcome.result).to eq 1111
      end
    end

    context "when request is invalid" do
      let(:outcome) { ValidatedCommand.run(value: 2222, valid: false) }

      it "does not execute successfully" do
        expect(outcome.failure?).to be true
      end

      it "has outcome type :validation" do
        expect(outcome.type).to eq :validation
      end

      it "returns error string as errors hash" do
        expect(outcome.result).to eq(errors: "Error Message")
      end
    end

    context "with virtus/active_model request object" do
      let(:outcome) { VirtusValidatedCommand.run(params) }

      context "when request is valid" do
        let(:params) { {name: "Young Tzu", age: "19"} }

        it "executes successfully" do
          expect(outcome.success?).to be true
        end
      end

      context "when request is invalid" do
        let(:params) { {name: "My Name"} }

        it "does not execute successfully" do
          expect(outcome.failure?).to be true
        end

        it "returns ActiveModel error object" do
          expect(outcome.result).to eq(age: ["can't be blank"])
        end
      end
    end
  end

  describe "#run!" do
    context "when command is invalid" do
      let(:outcome) { ControlledOutcome.run!(result: :invalid) }

      it "raises Tzu::Invalid" do
        expect { outcome }.to raise_error Tzu::Invalid, "Invalid Message"
      end
    end

    context "when command fails" do
      let(:outcome) { ControlledOutcome.run!(result: :failure) }

      it "raises Tzu::Failure" do
        expect { outcome }.to raise_error Tzu::Failure, "Failure Message"
      end
    end
  end
end
