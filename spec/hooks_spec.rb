# frozen_string_literal: true

RSpec.describe Tzu::Hooks do
  describe "#with_hooks" do
    def build_hooked(&block)
      hooked = Class.new.send(:include, Tzu::Hooks)

      hooked.class_eval do
        attr_reader :steps

        def self.process
          new.tap(&:process).steps
        end

        def initialize
          @steps = []
        end

        def process
          with_hooks({}) { steps << :process }
        end
      end

      hooked.class_eval(&block) if block
      hooked
    end

    context "when before hook is a method" do
      let(:hooked) do
        build_hooked do
          before :add_before

          def add_before(p)
            steps << :before
          end
        end
      end

      it "runs the before hook method" do
        expect(hooked.process).to eq([:before, :process])
      end
    end

    context "when before hook is a block" do
      let(:hooked) do
        build_hooked do
          before do
            steps << :before
          end
        end
      end

      it "runs the before hook block" do
        expect(hooked.process).to eq([:before, :process])
      end
    end

    context "when after hook is a method" do
      let(:hooked) do
        build_hooked do
          after :add_after

          def add_after(p)
            steps << :after
          end
        end
      end

      it "runs the after hook method" do
        expect(hooked.process).to eq([:process, :after])
      end
    end

    context "when after hook is a block" do
      let(:hooked) do
        build_hooked do
          after do
            steps << :after
          end
        end
      end

      it "runs the after hook block" do
        expect(hooked.process).to eq([:process, :after])
      end
    end

    context "when both before and after blocks are defined" do
      let(:hooked) do
        build_hooked do
          before do
            steps << :before
          end

          after do
            steps << :after
          end
        end
      end

      it "runs hooks in the expected order" do
        expect(hooked.process).to eq([:before, :process, :after])
      end
    end

    context "when both before and after methods are defined" do
      let(:hooked) do
        build_hooked do
          before :add_before
          after :add_after

          def add_before(p)
            steps << :before
          end

          def add_after(p)
            steps << :after
          end
        end
      end

      it "runs hooks in the expected order" do
        expect(hooked.process).to eq([:before, :process, :after])
      end
    end

    context "when multiple before methods are defined" do
      let(:hooked) do
        build_hooked do
          before :add_before1, :add_before2

          def add_before1(p)
            steps << :before1
          end

          def add_before2(p)
            steps << :before2
          end
        end
      end

      it "runs hooks in the expected order" do
        expect(hooked.process).to eq([:before1, :before2, :process])
      end
    end

    context "when multiple after methods are defined" do
      let(:hooked) do
        build_hooked do
          after :add_after1, :add_after2

          def add_after1(p)
            steps << :after1
          end

          def add_after2(p)
            steps << :after2
          end
        end
      end

      it "runs hooks in the expected order" do
        expect(hooked.process).to eq([:process, :after1, :after2])
      end
    end
  end
end
