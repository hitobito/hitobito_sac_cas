# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe People::ExternalInvoicePayedJob < BaseJob do
  let(:date) { Time.zone.today.next_year.end_of_year }

  subject(:job) { People::ExternalInvoicePayedJob.new(people(:mitglied).id, groups(:bluemlisalp_mitglieder).id, date.year) }

  it "executes membership manager update membership status" do
    allow(ExternalInvoice::SacMembership::MembershipManager).to receive(:update_membership_status)

    job.perform
  end
end
