# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::MembershipInvoicesController do
  let(:person) { people(:mitglied) }
  let(:today) { Time.zone.today }
  let(:bluemlisalp) { groups(:bluemlisalp) }

  before { sign_in(people(:admin)) }

  let(:params) do
    {
      group_id: groups(:bluemlisalp_mitglieder).id,
      person_id: person.id,
      people_membership_invoice_form: {
        reference_date: today,
        invoice_date: today,
        send_date: today,
        section_id: groups(:bluemlisalp).id,
        discount: 0
      }
    }
  end

  describe "GET new" do
    render_views
    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it "has checkbox to toggle and hidden fields" do
      get :new, params: params.except(:people_membership_invoice_form)

      expect(dom).to have_unchecked_field("Manuelle Differenzrechnung")
      expect(dom).to have_field "Zentralverbandsbeitrag", visible: false
    end

    it "toggles via stimulus" do
      get :new, params: params.except(:people_membership_invoice_form)
      expect(dom.find_field("Manuelle Differenzrechnung")["data-action"]).to eq "form-field-toggle#toggle"
      expect(dom).to have_css(".hidden[data-form-field-toggle-target=toggle]")
    end

    context "only neuanmeldung for stammsektion" do
      let(:person) do
        person = Fabricate(:person, birthday: 42.years.ago)
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: person,
          beitragskategorie: :adult,
          group: groups(:bluemlisalp_neuanmeldungen_nv))
        person
      end

      it "creates external invoice and enqueues job" do
        get :new, params: params.except(:people_membership_invoice_form)
        expect(dom).not_to have_unchecked_field("Manuelle Differenzrechnung")
        expect(dom).not_to have_field "Zentralverbandsbeitrag", visible: false
        expect(dom).not_to have_css(".hidden[data-form-field-toggle-target=toggle]")
      end
    end
  end

  describe "POST create" do
    it "creates external invoice and enqueues job" do
      expect do
        post :create,
          params: params.deep_merge(people_membership_invoice_form: {discount: 50, new_entry: true})
      end.to change { ExternalInvoice.count }.by(1)
        .and change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }

      expect(response).to redirect_to(external_invoices_group_person_path(
        groups(:bluemlisalp_mitglieder).id, person.id
      ))
      expect(flash[:notice]).to eq("Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt")

      job = Delayed::Job.last.payload_object
      expect(job.new_entry).to eq true
      expect(job.dont_send).to eq nil
      expect(job.discount).to eq 50
      expect(job.reference_date).to eq today
      expect(job.manual_positions).to eq({})
    end

    it "creates external invoice with manual positions and enqueues job" do
      manual_positions_params = {
        people_membership_invoice_form: {
          discount: nil,
          section_id: 0,
          sac_fee: 100,
          sac_entry_fee: 120,
          hut_solidarity_fee: 50,
          sac_magazine: 30,
          sac_magazine_postage_abroad: 10,
          section_entry_fee: 70,
          section_fees_attributes: {
            "0" => {section_id: bluemlisalp.id, fee: 140},
            "1" => {section_id: groups(:matterhorn).id, fee: 130}
          }
        }
      }
      expect do
        post :create,
          params: params.deep_merge(manual_positions_params)
      end.to change { ExternalInvoice.count }.by(1)
        .and change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }

      expect(response).to redirect_to(external_invoices_group_person_path(
        groups(:bluemlisalp_mitglieder).id, person.id
      ))
      expect(flash[:notice]).to eq("Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt")

      job = Delayed::Job.last.payload_object
      expect(job.manual_positions).to eq(
        {"sac_fee" => 100.to_d,
         "sac_entry_fee" => 120.to_d,
         "hut_solidarity_fee" => 50.to_d,
         "sac_magazine" => 30.to_d,
         "sac_magazine_postage_abroad" => 10.to_d,
         "section_entry_fee" => 70.to_d,
         "section_fees" => [
           {"section_id" => bluemlisalp.id, "fee" => 140.to_d},
           {"section_id" => groups(:matterhorn).id, "fee" => 130.to_d}
         ],
         "section_bulletin_postage_abroads" => nil}
      )
    end

    it "does not create external when invoice form is invalid" do
      expect do
        post :create, params: params.deep_merge(people_membership_invoice_form: {send_date: ""})
      end.not_to change { ExternalInvoice.count }
      expect(response).to have_http_status(422)
    end

    context "data quality errors" do
      before { person.update!(data_quality: :error) }

      it "logs and marks invoice as error if person has data quality errors" do
        expect { post :create, params: }
          .to change { ExternalInvoice.count }.by(1)
          .and change { HitobitoLogEntry.count }.by(1)
          .and not_change { Delayed::Job.count }

        expect(response).to redirect_to(external_invoices_group_person_path(
          groups(:bluemlisalp_mitglieder).id, person.id
        ))
        expect(flash[:alert])
          .to eq("Die Person hat Datenqualitätsprobleme, daher wurde keine Rechnung erstellt.")
      end
    end

    context "only neuanmeldung for stammsektion" do
      let(:person) do
        person = Fabricate(:person, birthday: 42.years.ago)
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name.to_sym,
          person: person,
          beitragskategorie: :adult,
          group: groups(:bluemlisalp_neuanmeldungen_nv))
        person
      end

      it "creates external invoice and enqueues job" do
        expect do
          post :create,
            params: params.deep_merge(
              people_membership_invoice_form: {
                discount: 50, new_entry: true, dont_send: true
              }
            )
        end.to change { ExternalInvoice.count }.by(1)
          .and change { Delayed::Job.where("handler like '%CreateMembershipInvoiceJob%'").count }

        expect(response).to redirect_to(external_invoices_group_person_path(
          groups(:bluemlisalp_mitglieder).id, person.id
        ))
        expect(flash[:notice])
          .to eq("Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt")

        job = Delayed::Job.last.payload_object
        expect(job.new_entry).to eq true
        expect(job.dont_send).to eq true
        expect(job.discount).to eq 50
        expect(job.reference_date).to eq today
      end
    end
  end
end
