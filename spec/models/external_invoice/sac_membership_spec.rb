# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe ExternalInvoice::SacMembership, :tests_active_jobs do
  describe "after_update callback" do
    let(:external_invoice) { ExternalInvoice::SacMembership.create!(state: :draft, person: people(:mitglied), link: groups(:bluemlisalp_mitglieder)) }

    context "state changes to payed" do
      it "enques job" do
        expect_enqueued_job do
          external_invoice.update!(state: :payed)
        end
      end
    end

    context "when the state does not change to payed" do
      it "does not queue the job" do
        expect_no_enqueued_job do
          external_invoice.update!(state: :draft)
          external_invoice.update!(state: :open)
        end
      end
    end

    context "when state is already payed" do
      let(:payed_external_invoice) { ExternalInvoice::SacMembership.create!(state: :payed, person: people(:mitglied), link: groups(:bluemlisalp_mitglieder)) }

      it "does not queue the job" do
        expect_no_enqueued_job do
          payed_external_invoice.update!(person: people(:familienmitglied))
          payed_external_invoice.update!(state: :open)
        end
      end
    end

    def expect_no_enqueued_job
      expect do
        yield
      end.not_to change { Delayed::Job.where('handler like "%People::ExternalInvoicePayedJob%"').count }
    end

    def expect_enqueued_job
      expect do
        yield
      end.to change { Delayed::Job.where('handler like "%People::ExternalInvoicePayedJob%"').count }
    end
  end
end
