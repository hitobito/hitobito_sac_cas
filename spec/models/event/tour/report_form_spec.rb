# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Tour::ReportForm do
  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }
  let(:participation) do
    Fabricate(Event::Role::Participant.name.to_sym,
      participation: Fabricate(:event_participation, participant: people(:mitglied), event: event)
    ).participation
  end
  let(:form) { described_class.new(report) }

  it "assigns attributes from report" do
    expect(form.review).to eq(report.review)
    expect(form.remarks).to eq(report.remarks)
  end

  describe "#save" do
    it "persists changed attributes to the report" do
      form.review = "Updated review"
      form.remarks = "Some remarks"

      expect { form.save }
        .to change { report.reload.review }.to("Updated review")
        .and change { report.reload.remarks }.to("Some remarks")
    end

    it "perists changed attributes to the participations" do
      form.participations_attributes = {
        participation.id.to_s => {
          state: "attended",
          means_of_transport: "legs"
        }
      }

      expect { form.save }
        .to change { participation.reload.state }.from("assigned").to("attended")
        .and change { participation.reload.means_of_transport }.from(nil).to("legs")
    end
  end

  describe "#participations" do
    [:rejected, :applied, :unconfirmed].each do |state|
      it "does not include participations in state #{state}" do
        participation.update_column(:state, state)

        expect(form.participations).not_to include(participation)
      end
    end
  end

  describe "#editable_participation_state?" do
    it "returns true for an editable state" do
      participation.update_columns(state: "assigned")
      expect(form.editable_participation_state?(participation)).to be true
    end

    it "returns false for a non editable state" do
      participation.update_columns(state: "canceled")
      expect(form.editable_participation_state?(participation)).to be false
    end
  end

  describe "#assert_participation_states_editable" do
    it "is valid when participation is in an editable state" do
      participation.update_columns(state: "assigned")
      form.participations_attributes = {
        participation.id.to_s => {
          state: "attended"
        }
      }

      expect(form).to be_valid
    end

    it "is invalid when participation is in a non editable state" do
      participation.update_columns(state: "canceled")
      form.participations_attributes = {
        participation.id.to_s => {
          state: "attended"
        }
      }

      expect(form).not_to be_valid
    end
  end

  describe "#tour_completed?" do
    it "returns false when tour is in progress states" do
      expect(form.tour_completed?).to be_falsey
    end

    it "returns true when tour is ready" do
      event.update_column(:state, :ready)

      expect(form.tour_completed?).to be_truthy
    end

    it "returns true when tour is closed" do
      event.update_column(:state, :closed)

      expect(form.tour_completed?).to be_truthy
    end
  end
end
