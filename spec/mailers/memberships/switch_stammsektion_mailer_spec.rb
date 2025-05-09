# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::SwitchStammsektionMailer do
  let(:person) { people(:admin) }
  let(:group) { groups(:bluemlisalp) }
  let(:previous_group) { groups(:matterhorn) }
  let(:mail) { described_class.confirmation(person, group, previous_group) }

  subject { mail.parts.first.body }

  it "sends confirmation email to person" do
    expect(mail.to).to match_array(["support@hitobito.example.com"])
    expect(mail.bcc).to include(SacCas::MV_EMAIL)
    expect(mail.bcc).to include("bluemlisalp@sac.ch")
    expect(mail.bcc).to include("matterhorn@sac.ch")
    expect(mail.subject).to eq "Bestätigung Sektionswechsel"
    expect(mail.body).to match("Hallo Anna Admin")
    expect(mail.body).to match("Der Sektionswechsel zu SAC Blüemlisalp wurde vorgenommen.")
  end

  it "sends confirmation email to geschaefsstelle if configured" do
    groups(:geschaeftsstelle).update!(email: "geschaeftsstelle@example.com")
    expect(mail.cc).to eq ["geschaeftsstelle@example.com"]
  end
end
