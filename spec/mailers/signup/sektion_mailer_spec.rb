# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Signup::SektionMailer do
  let(:person) { people(:mitglied) }

  context "sektion requiring approval" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
    let(:mail) { described_class.approval_pending_confirmation(person, group.layer_group) }

    it "sends confirmation email" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include(SacCas::MV_EMAIL)
      expect(mail.subject).to eq("SAC Eintritt Bestellbestätigung")
      expect(mail.body.to_s).to include("Sektion: SAC Blüemlisalp", "Vielen Dank")
    end
  end

  context "sektion not requiring approval" do
    let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
    let(:mail) { described_class.confirmation(person, group.layer_group) }

    it "sends confirmation email" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include(SacCas::MV_EMAIL)
      expect(mail.subject).to eq("SAC Eintritt Bestellbestätigung")
      expect(mail.body.to_s).to include(
        "Sektion: SAC Blüemlisalp",
        "Mitgliedschaftskategorie: Einzel",
        "Geburtsdatum: 01.01.2000",
        "Strasse und Nr: Ophovenerstrasse 79a",
        "Viel Spass beim SAC!"
      )
    end
  end
end
