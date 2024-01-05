# frozen_string_literal: true

RSpec.describe Tzu::Outcome do
  context "outcome is failed with specified type" do
    subject { Tzu::Outcome.new(false, "abc", :validation) }

    it "calls appropriate handler" do
      matched = false
      subject.handle do
        success { raise }
        failure(:something) { raise }
        failure(:validation) { matched = true }
      end
      expect(matched).to eq true
    end
  end

  context "outcome is failed with unspecified type" do
    subject { Tzu::Outcome.new(false, "abc", :validation) }

    it "calls appropriate handler" do
      matched = false
      subject.handle do
        success { raise }
        failure { matched = true }
        failure(:validation) { raise }
      end
      expect(matched).to eq true
    end
  end

  context "outcome is successful" do
    subject { Tzu::Outcome.new(true, "abc") }

    it "calls success handler" do
      matched = false
      subject.handle do
        success { matched = true }
        failure(:something) { raise }
      end
      expect(matched).to eq true
    end
  end
end
