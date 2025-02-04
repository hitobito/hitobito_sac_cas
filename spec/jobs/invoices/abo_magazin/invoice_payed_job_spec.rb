# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::AboMagazin::InvoicePayedJob do
  let(:group) { groups(:abo_die_alpen) }
  let(:person) { people(:abonnent) }

  subject(:job) { described_class.new(person.id, group.id) }

  it "executes membership manager update membership status" do
    expect_any_instance_of(Invoices::AboMagazin::AbonnentManager).to receive(:update_abonnent_status)

    job.perform
  end
end
