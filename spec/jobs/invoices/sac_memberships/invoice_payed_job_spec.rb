# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::SacMemberships::InvoicePayedJob do
  let(:date) { Time.zone.today.next_year.end_of_year }

  subject(:job) { described_class.new(people(:mitglied).id, groups(:bluemlisalp_mitglieder).id, date.year) }

  it "executes membership manager update membership status" do
    allow(Invoices::SacMemberships::MembershipManager).to receive(:update_membership_status)

    job.perform
  end
end
