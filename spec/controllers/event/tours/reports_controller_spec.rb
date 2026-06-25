# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Tours::ReportsController do
  let(:group) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:params) { {group_id: group.id, event_id: event.id} }

  before do
    allow_any_instance_of(Event::Tour).to receive(:reportable?).and_return(true)
    sign_in(person)
  end

  describe "GET#edit" do
    context "as mitglied" do
      let(:person) { people(:mitglied) }

      it "is unauthorized" do
        expect { get :edit, params: params }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      let(:person) { people(:admin) }

      it "renders edit form" do
        get :edit, params: params

        expect(response).to be_successful
      end

      it "is unauthorized when event is not reportable" do
        allow_any_instance_of(Event::Tour).to receive(:reportable?).and_return(false)

        expect { get :edit, params: params }.to raise_error(CanCan::AccessDenied)
      end
    end
  end

  describe "PUT#update" do
    context "as mitglied" do
      let(:person) { people(:mitglied) }

      it "is unauthorized" do
        expect { put :update, params: params }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      let(:person) { people(:admin) }

      it "updates the report and redirects to event show" do
        put :update, params: params.merge(
          event_tour_report_form: {
            remarks: "I have an opinion",
            review: "My opinion is more important than yours"
          }
        )

        report = event.report.reload

        expect(flash[:notice]).to eq "Tourenrapport wurde erfolgreich aktualisiert"
        expect(response).to redirect_to(group_event_path(group, event))
        expect(report.remarks).to eq "I have an opinion"
        expect(report.review).to eq "My opinion is more important than yours"
      end

      it "is unauthorized when event is not reportable" do
        allow_any_instance_of(Event::Tour).to receive(:reportable?).and_return(false)

        expect { put :update, params: params }.to raise_error(CanCan::AccessDenied)
      end
    end
  end
end
