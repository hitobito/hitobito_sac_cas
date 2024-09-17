# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::SacMembershipsMailer do
  let(:person) { people(:mitglied) }
  let(:mail) { described_class.confirmation(person) }

  it "sends confirmation email to person" do
    expect(mail.body.to_s).to include("Hallo Edmund,", "Vielen Dank für deine Zahlung, welche bei uns eingegangen ist.")
  end
end
