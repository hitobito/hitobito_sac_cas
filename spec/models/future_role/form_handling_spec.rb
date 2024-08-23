# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe FutureRole::FormHandling do
  shared_examples "register_on_options" do
    let(:model) { described_class.new }

    describe "register_on_date" do
      it "equals nil for now" do
        travel_to(Time.zone.local(2024, 6, 30)) do
          model.register_on = "now"
          expect(model.register_on_date).to be_nil
        end
      end

      it "equals first of july for jul" do
        travel_to(Time.zone.local(2024, 6, 30)) do
          model.register_on = "jul"
          expect(model.register_on_date).to eq Date.new(2024, 7, 1)
        end
      end

      it "equals first of october for oct" do
        travel_to(Time.zone.local(2024, 7, 30)) do
          model.register_on = "oct"
          expect(model.register_on_date).to eq Date.new(2024, 10, 1)
        end
      end
    end

    describe "register_on_options" do
      it "includes now and jul on 31 of june" do
        travel_to(Time.zone.local(2024, 6, 30)) do
          expect(model.register_on_options).to eq [
            ["now", "sofort"],
            ["jul", "01. Juli"]
          ]
        end
      end

      it "includes now and oct on first of july" do
        travel_to(Time.zone.local(2024, 7, 1)) do
          expect(model.register_on_options).to eq [
            ["now", "sofort"],
            ["oct", "01. Oktober"]
          ]
        end
      end

      it "includes only now on first of oct" do
        travel_to(Time.zone.local(2024, 10, 1)) do
          expect(model.register_on_options).to eq [
            ["now", "sofort"]
          ]
        end
      end
    end
  end

  describe Wizards::Steps::Signup::Sektion::VariousFields do
    it_behaves_like "register_on_options" do
      let(:model) { described_class.new(double(:wizard)) }
    end
  end
end
