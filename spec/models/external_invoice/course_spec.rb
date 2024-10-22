# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe ExternalInvoice::CourseParticipation do
  let(:date) { Date.new(2023, 1, 1) }
  let(:mitglied) { people(:mitglied) }
  let(:kind) { event_kinds(:ski_course) }
  let(:course) { Fabricate(:sac_course, kind: kind) }
  let(:participation) { Fabricate(:event_participation, event: course, person: mitglied, price: 20, price_category: 1) }
  let(:external_invoice) {
    Fabricate(:external_invoice,
      person: mitglied,
      link: participation,
      state: :draft,
      issued_at: date,
      sent_at: date,
      year: date.year,
      total: 0,
      type: "ExternalInvoice::CourseParticipation")
  }

  describe "after_save callback" do
    it "updates participation state to payed" do
      external_invoice.update!(state: :payed)
      expect(participation.invoice_state).to eq("payed")
    end

    context "multiple invoices" do
      let(:old_external_invoice) { ExternalInvoice::CourseParticipation.create!(person: mitglied, link: participation, created_at: external_invoice.created_at - 2.days) }

      it "updates state if newest invoice" do
        external_invoice.update!(state: :payed)
        expect(participation.invoice_state).to eq("payed")
      end

      it "does not update invoice_state if invoice is old" do
        old_external_invoice.update!(state: :payed)
        expect(participation.invoice_state).to eq("draft")
      end
    end
  end
end
