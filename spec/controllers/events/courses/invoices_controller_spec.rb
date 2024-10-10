# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Events::Courses::InvoicesController do
  let(:admin) { people(:admin) }
  let(:participant) { people(:mitglied) }
  let(:event) { Fabricate(:sac_open_course) }
  let(:participation) { Fabricate(:event_participation, event:, person: participant, price: 10, application_id: -1) }
  let(:params) { {group_id: event.group_ids.first, event_id: event.id, id: participation.id} }

  describe "POST#create" do
    context "as participant" do
      before { sign_in(participant) }

      it "is unauthorized" do
        expect { post :create, params: }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "enqueues invoice job" do
        expect { post :create, params: }
          .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count).by(1)
        expect(response).to redirect_to(group_event_participation_path(params))
        expect(flash[:notice]).to eq("Rechnung wurde erfolgreich erstellt.")
      end

      it "doesn't enqueue invoice job if participation price is missing" do
        participation.update(price: nil)

        expect { post :create, params: }.not_to change(Delayed::Job, :count)
        expect(flash[:alert]).to eq("Rechnung konnte nicht erstellt werden wegen fehlendem Teilnahmepreis.")
      end
    end
  end
end
