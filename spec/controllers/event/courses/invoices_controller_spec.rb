# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::Courses::InvoicesController do
  let(:admin) { people(:admin) }
  let(:participant) { people(:mitglied) }
  let(:event) { Fabricate(:sac_open_course, price_member: 5, price_regular: 10) }
  let(:participation) { Fabricate(:event_participation, event:, participant: participant, price: 10, price_category: "price_regular", application_id: -1) }
  let(:params) { {group_id: event.group_ids.first, event_id: event.id, participation_id: participation.id} }

  describe "GET#new" do
    context "as participant" do
      before { sign_in(participant) }

      it "is unauthorized" do
        expect { get :new, params: }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "is unauthorized for leader participations" do
        Fabricate(Event::Course::Role::Leader.name.to_sym, participation: participation)
        expect { get :new, params: }.to raise_error(CanCan::AccessDenied)
      end

      it "renders form with date fields set to today" do
        get :new, params: params
        expect(assigns(:invoice_form).reference_date).to eq Time.zone.today
        expect(assigns(:invoice_form).invoice_date).to eq Time.zone.today
        expect(assigns(:invoice_form).send_date).to eq Time.zone.today
      end
    end
  end

  describe "GET#recalculate" do
    context "as participant" do
      before { sign_in(participant) }

      it "is unauthorized" do
        expect { get :recalculate, params: }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "is unauthorized for leader participations" do
        Fabricate(Event::Course::Role::Leader.name.to_sym, participation: participation)
        expect { get :recalculate, params: }.to raise_error(CanCan::AccessDenied)
      end

      it "recalculates price when price_category changed" do
        params[:event_participation_invoice_form] = {price_category: "price_member"}
        get :recalculate, params: params
        expect(JSON.parse(response.body)["value"]).to eq "5.0"
      end

      it "returns unprocessable_entity when invalid price_category is passed" do
        params[:event_participation_invoice_form] = {price_category: "this_price_category_doesnt_exist"}
        get :recalculate, params: params
        expect(response.status).to eq 422
      end

      it "recalculates price when reference_date changed" do
        params[:event_participation_invoice_form] = {reference_date: "12.12.2025"}
        get :recalculate, params: params
        expect(JSON.parse(response.body)["value"]).to eq "10.0"
      end

      it "returns unprocessable_entity when invalid reference_date is passed" do
        params[:event_participation_invoice_form] = {reference_date: "12.12"}
        get :recalculate, params: params
        expect(response.status).to eq 422
      end

      it "returns not found when unknown query param is passed" do
        params[:event_participation_invoice_form] = {unknown_query_param: "price_member"}
        get :recalculate, params: params
        expect(response.status).to eq 400
      end
    end
  end

  describe "POST#create" do
    context "as participant" do
      before { sign_in(participant) }

      it "is unauthorized" do
        expect { post :create, params: }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "as admin" do
      before do
        sign_in(admin)
        params[:event_participation_invoice_form] = {
          reference_date: "12.12.2025",
          invoice_date: "12.12.2025",
          send_date: "12.12.2025",
          price_category: "price_member",
          price: 4000
        }
      end

      it "is unauthorized for leader participations" do
        Fabricate(Event::Course::Role::Leader.name.to_sym, participation: participation)
        expect { post :create, params: }.to raise_error(CanCan::AccessDenied)
      end

      it "enqueues invoice job and updates price and price_category on participation" do
        expect { post :create, params: }
          .to change(Delayed::Job.where("handler LIKE '%CreateCourseInvoiceJob%'"), :count).by(1)
          .and change(ExternalInvoice, :count).by(1)
        expect(flash[:notice]).to eq("Rechnung wurde erfolgreich erstellt.")
        expect(participation.reload.price_category).to eq "price_member"
        expect(participation.reload.price).to eq 4000
        expect(ExternalInvoice.last.issued_at).to eq Date.new(2025, 12, 12)
        expect(ExternalInvoice.last.sent_at).to eq Date.new(2025, 12, 12)
      end

      it "does not update price and price_category when participation state is absent but enqueses job with passed price" do
        expect(ExternalInvoice::CourseAnnulation).to receive(:invoice!).with(participation, hash_including(custom_price: 4000))
        participation.update_column(:state, "absent")
        post :create, params: params
        expect(participation.reload.price_category).not_to eq "price_member"
        expect(participation.reload.price).not_to eq 4000
      end

      it "doesn't enqueue invoice job if invoice_form is invalid" do
        params[:event_participation_invoice_form][:reference_date] = nil
        expect { post :create, params: }.not_to change(Delayed::Job, :count)
      end
    end
  end
end
