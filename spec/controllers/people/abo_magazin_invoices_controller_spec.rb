# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::AboMagazinInvoicesController do
  let(:person) { people(:abonnent) }
  let(:group) { groups(:abo_die_alpen) }
  let(:today) { Time.zone.today }

  before { sign_in(people(:admin)) }

  let(:params) do
    {
      group_id: group.id,
      person_id: person.id,
      external_invoice: {
        sent_at: today,
        link_id: group.id
      }
    }
  end

  describe "POST create" do
    it "creates external invoice and enqueues job" do
      expect do
        post :create, params: params
      end.to change { ExternalInvoice.count }.by(1)
        .and change { Delayed::Job.where("handler like '%CreateAboMagazinInvoiceJob%'").count }

      expect(flash[:notice]).to eq("Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt")
      expect(ExternalInvoice.last.link).to eq group
      expect(ExternalInvoice.last.issued_at).to eq roles(:abonnent_alpen).end_on + 1.day
      expect(ExternalInvoice.last.sent_at).to eq today
    end

    it "creates external invoice and enqueues job with multiple mailing lists available" do
      Fabricate(Group::AboMagazin::Abonnent.sti_name.to_sym, group: Fabricate(Group::AboMagazin.sti_name.to_sym, parent: groups(:abo_magazine)), person:, end_on: 2.years.ago)
      Fabricate(Group::AboMagazin::Neuanmeldung.sti_name.to_sym, group: Fabricate(Group::AboMagazin.sti_name.to_sym, parent: groups(:abo_magazine)), person:, end_on: 2.years.ago)

      expect do
        post :create, params: params
      end.to change { ExternalInvoice.count }.by(1)
        .and change { Delayed::Job.where("handler like '%CreateAboMagazinInvoiceJob%'").count }

      expect(flash[:notice]).to eq("Die gewünschte Rechnung wird erzeugt und an Abacus übermittelt")
      expect(ExternalInvoice.last.link).to eq group
      expect(ExternalInvoice.last.issued_at).to eq roles(:abonnent_alpen).end_on + 1.day
      expect(ExternalInvoice.last.sent_at).to eq today
    end

    it "logs and marks invoice as error if person has data quality errors" do
      person.update!(data_quality: :error)
      expect { post :create, params: }
        .to change { ExternalInvoice.count }.by(1)
        .and change { HitobitoLogEntry.count }.by(1)
        .and not_change { Delayed::Job.count }

      expect(response).to redirect_to(external_invoices_group_person_path(group.id, person.id))
      expect(flash[:alert]).to eq "Die Person hat Datenqualitätsprobleme, daher wurde keine Rechnung erstellt."
    end
  end
end
