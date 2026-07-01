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
      participation: Fabricate(:event_participation, participant: people(:mitglied), event: event)).participation
  end
  let(:revenue) { event_costs(:participation_fee) }
  let(:expenditure) { event_costs(:transport) }
  let(:receipt) { event_cost_receipts(:tankstelle) }
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

    it "persists changes to existing revenue" do
      form.revenues_attributes = {
        "0" => {
          id: revenue.id,
          description: "something else"
        }
      }

      expect { form.save }.to change { revenue.reload.description }.to("something else")
    end

    it "persists new revenue" do
      form.revenues_attributes = {
        "0" => {
          description: "New revenue",
          count: "3",
          amount: "50"
        }
      }

      expect { form.save }.to change { report.costs.where(income: true).count }.by(1)
    end

    it "destroys revenue marked for destruction" do
      form.revenues_attributes = {
        "0" => {
          id: revenue.id,
          _destroy: "1"
        }
      }

      expect { form.save }.to change { report.costs.count }.by(-1)
    end

    it "persists changes to existing expenditure" do
      form.expenditures_attributes = {
        "0" => {
          id: expenditure.id,
          description: "something else"
        }
      }

      expect { form.save }.to change { expenditure.reload.description }.to("something else")
    end

    it "persists new expenditure" do
      form.expenditures_attributes = {
        "0" => {
          description: "New expenditure",
          count: "2",
          amount: "75"
        }
      }

      expect { form.save }.to change { report.costs.where(income: false).count }.by(1)
    end

    it "destroys expenditure marked for destruction" do
      form.expenditures_attributes = {
        "0" => {
          id: expenditure.id,
          _destroy: "1"
        }
      }

      expect { form.save }.to change { report.costs.count }.by(-1)
    end

    it "persists changes to existing receipt" do
      form.receipts_attributes = {
        "0" => {
          id: receipt.id,
          description: "new receipt name or something"
        }
      }

      expect { form.save }.to change { receipt.reload.description }.to("new receipt name or something")
    end

    it "persists new receipt" do
      form.receipts_attributes = {
        "0" => {
          description: "New receipt",
          file: fixture_file_upload("icon.png", "image/png")
        }
      }

      expect { form.save }.to change { report.cost_receipts.count }.by(1)
    end

    it "destroys receipt marked for destruction" do
      form.receipts_attributes = {
        "0" => {
          id: receipt.id,
          _destroy: "1"
        }
      }

      expect { form.save }.to change { report.cost_receipts.count }.by(-1)
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

  describe "#revenues" do
    it "returns costs with income true" do
      expect(form.revenues).to include(revenue)
      expect(form.revenues).not_to include(expenditure)
    end
  end

  describe "#expenditures" do
    it "returns costs with income false" do
      expect(form.expenditures).to include(expenditure)
      expect(form.expenditures).not_to include(revenue)
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

  describe "#assert_cost_records_valid" do
    it "is valid" do
      expect(form).to be_valid
    end

    it "is not valid if revenue is invalid" do
      form.revenues_attributes = {
        "0" => {
          id: revenue.id,
          description: ""
        }
      }

      expect(form).not_to be_valid
      expect(form.errors.full_messages).to match_array ["Bezeichnung muss ausgefüllt werden"]
      expect(form.revenues.first.errors.full_messages).to match_array ["Bezeichnung muss ausgefüllt werden"]
    end

    it "is not valid if expenditure is invalid" do
      form.expenditures_attributes = {
        "0" => {
          id: expenditure.id,
          description: ""
        }
      }

      expect(form).not_to be_valid
      expect(form.errors.full_messages).to match_array ["Bezeichnung muss ausgefüllt werden"]
      expect(form.expenditures.first.errors.full_messages).to match_array ["Bezeichnung muss ausgefüllt werden"]
    end

    it "is not valid if receipt is invalid" do
      form.receipts_attributes = {
        "0" => {
          id: receipt.id,
          description: ""
        }
      }

      expect(form).not_to be_valid
      expect(form.errors.full_messages).to match_array ["Beschreibung muss ausgefüllt werden"]
      expect(form.receipts.first.errors.full_messages).to match_array ["Beschreibung muss ausgefüllt werden"]
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
