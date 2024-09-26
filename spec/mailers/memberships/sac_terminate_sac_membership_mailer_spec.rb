# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::TerminateSacMembershipMailer do
  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp) }
  let(:switch_on) { "sofort" }
  let(:mail) { described_class.confirmation(person, group.display_name, switch_on) }

  subject { mail.parts.first.body }

  it "sends confirmation email to person" do
    expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
    expect(mail.subject).to eq "Der SAC Austritt wurde per sofort vorgenommen"
    expect(mail.body).to match("Hallo Edmund Hillary,")
    expect(mail.body).to match("Der SAC Austritt wurde per sofort vorgenommen.")
  end

  it "sends confirmation email to geschaefsstelle if configured" do
    groups(:geschaeftsstelle).update!(email: "geschaeftsstelle@example.com")
    expect(mail.cc).to eq ["geschaeftsstelle@example.com"]
  end
end
