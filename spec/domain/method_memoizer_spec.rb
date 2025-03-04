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
end
