# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::YearlyMembershipInvoicesController do
  let(:today) { Time.zone.today }

  before { sign_in(people(:admin)) }

  let(:params) do
    {
      group_id: Group.root.id,
      people_yearly_membership_invoice_form: {
        invoice_year: today.year,
        invoice_date: today,
        send_date: today,
        role_finish_date: today + 1.year
      }
    }
  end

  describe "POST create" do
    it "schedules job" do
      expect do
        post :create, params: params
      end.to change { Delayed::Job.where('handler like "%CreateYearlyInvoicesJob%"').count }.by(1)

      expect(response).to redirect_to(group_path(Group.root))
      expect(flash[:notice]).to eq("Der Jahresinkassolauf wurde erfolgreich gestartet.")

      job = Delayed::Job.last.payload_object
      expect(job.instance_variable_get(:@invoice_year)).to eq today.year
      expect(job.instance_variable_get(:@invoice_date)).to eq today
      expect(job.instance_variable_get(:@send_date)).to eq today
      expect(job.instance_variable_get(:@role_finish_date)).to eq today + 1.year
    end

    it "does not schedule job when invoice form is invalid" do
      expect do
        post :create, params: params.deep_merge(people_yearly_membership_invoice_form: {invoice_year: today + 3.years})
      end.not_to change { Delayed::Job.count }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not schedule a second job if one is already running" do
      Invoices::Abacus::CreateYearlyInvoicesJob.new(**params[:people_yearly_membership_invoice_form]).enqueue!(run_at: 10.seconds.from_now)

      expect do
        post :create, params: params
      end.to_not change { Delayed::Job.count }

      expect(response).to redirect_to(group_path(Group.root))
      expect(flash[:notice]).to eq("Der Jahresinkassolauf wurde erfolgreich gestartet.")
    end
  end
end
