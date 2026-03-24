# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Migrations::AddBeitragskategorieToMembershipExternalInvoicesJob do
  let(:job) { described_class.new }

  let!(:invoice_for_family_member) { Fabricate(:sac_membership_invoice, person: family_member) }
  let(:family_member) { people(:familienmitglied) }
  let!(:invoice_for_adult) { Fabricate(:sac_membership_invoice, person: adult) }
  let(:adult) { people(:mitglied) }
  let!(:non_membership_invoice) { Fabricate(:external_invoice, person: adult) }

  before do
    ExternalInvoice.update_all(beitragskategorie: nil)
  end

  it "migrates beitragskategorie over from person stammsektion role" do
    expect(invoice_for_family_member.reload.beitragskategorie).to be_nil
    expect(invoice_for_adult.reload.beitragskategorie).to be_nil

    job.perform

    expect(invoice_for_family_member.reload.beitragskategorie).to eq("family")
    expect(invoice_for_adult.reload.beitragskategorie).to eq("adult")
  end

  it "does not migrate non membership invoice" do
    expect(non_membership_invoice.reload.beitragskategorie).to be_nil

    job.perform

    expect(non_membership_invoice.reload.beitragskategorie).to be_nil
  end

  it "does not fill beitragskategorie if no membership in invoice year" do
    invoice_for_family_member.update(year: family_member.roles.first.start_on.year - 1)
    expect(invoice_for_family_member.reload.beitragskategorie).to be_nil

    job.perform

    expect(invoice_for_family_member.reload.beitragskategorie).to be_nil
  end
end
