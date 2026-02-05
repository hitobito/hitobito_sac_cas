# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe MethodMemoizer do
  before do
    stub_const("TestMemoizer", Class.new do
      include MethodMemoizer

      def work_method_a = "value a"

      def memoized_method_a
        work_method_a
      end
      memoize_method :memoized_method_a

      def work_method_b = "value b"

      def memoized_method_b
        work_method_b
      end
      memoize_method :memoized_method_b

      def work_method_with_args(arg1, arg2)
        "#{arg1} + #{arg2}"
      end

      def memoized_method_with_args(arg1, arg2)
        work_method_with_args(arg1, arg2)
      end
      memoize_method :memoized_method_with_args

      def work_method_with_block(&block)
        block.call if block
      end

      def memoized_method_with_block(&block)
        work_method_with_block(&block)
      end
      memoize_method :memoized_method_with_block

      def work_method_false
        false
      end

      def memoized_method_false
        work_method_false
      end
      memoize_method :memoized_method_false
    end)
  end

  subject(:instance) { TestMemoizer.new }

  it "memoized_method is private" do
    expect { TestMemoizer.new.memoized_method }.to raise_error(NoMethodError)
  end

  it "returns the result of the block" do
    allow(instance).to receive(:work_method_a).and_return("expected value")
    expect(instance.memoized_method_a).to eq("expected value")
  end

  it "does not call the block on subsequent calls" do
    allow(instance).to receive(:work_method_a).and_return("expected value")
    expect(instance).to receive(:work_method_a).once
    expect(instance.memoized_method_a).to eq("expected value")
    expect(instance.memoized_method_a).to eq("expected value")
  end

  it "does not return memoized value of another method" do
    expect(instance.memoized_method_a).to eq instance.work_method_a
    expect(instance.memoized_method_b).not_to eq instance.memoized_method_a
  end

  it "returns nil if block returns nil" do
    allow(instance).to receive(:work_method_a).and_return(nil)
    expect(instance.memoized_method_a).to be_nil
  end

  it "returns memoized nil value without calling the block" do
    allow(instance).to receive(:work_method_a).and_return(nil)
    expect(instance).to receive(:work_method_a).once
    instance.memoized_method_a
    instance.memoized_method_a
  end

  it "returns false if method returns false" do
    allow(instance).to receive(:work_method_false).and_return(false)
    expect(instance.memoized_method_false).to be false
  end

  it "returns memoized false value without calling the method again" do
    allow(instance).to receive(:work_method_false).and_return(false)
    expect(instance).to receive(:work_method_false).once
    instance.memoized_method_false
    instance.memoized_method_false
  end

  context "with arguments" do
    it "memoizes different values for different arguments" do
      allow(instance).to receive(:work_method_with_args).and_call_original
      expect(instance).to receive(:work_method_with_args).twice

      result1 = instance.memoized_method_with_args(1, 2)
      result2 = instance.memoized_method_with_args(3, 4)

      expect(result1).to eq("1 + 2")
      expect(result2).to eq("3 + 4")
    end

    it "returns cached value for same arguments" do
      allow(instance).to receive(:work_method_with_args).and_call_original
      expect(instance).to receive(:work_method_with_args).once

      result1 = instance.memoized_method_with_args(1, 2)
      result2 = instance.memoized_method_with_args(1, 2)

      expect(result1).to eq("1 + 2")
      expect(result2).to eq("1 + 2")
    end
  end

  context "with blocks" do
    it "memoizes block results by source location" do
      allow(instance).to receive(:work_method_with_block).and_call_original

      block = proc { "block result" }

      expect(instance).to receive(:work_method_with_block).once
      result1 = instance.memoized_method_with_block(&block)
      result2 = instance.memoized_method_with_block(&block)

      expect(result1).to eq("block result")
      expect(result2).to eq("block result")
    end

    it "treats different blocks as different cache keys" do
      allow(instance).to receive(:work_method_with_block).and_call_original

      expect(instance).to receive(:work_method_with_block).twice
      result1 = instance.memoized_method_with_block { "block 1" }
      result2 = instance.memoized_method_with_block { "block 2" }

      expect(result1).to eq("block 1")
      expect(result2).to eq("block 2")
    end
  end
end
