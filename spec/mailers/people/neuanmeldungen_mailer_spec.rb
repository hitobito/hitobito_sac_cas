# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::NeuanmeldungenMailer do
  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp) }

  subject { mail.parts.first.body }

  describe "approve" do
    let(:mail) { described_class.approve(person, group) }

    it "sends confirmation email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "SAC Eintritt Antragsbestätigung"
      expect(mail.bcc).to include "mv@sac-cas.ch"
      expect(mail.body).to match("Hallo Edmund,")
      expect(mail.body).to match("Die SAC Blüemlisalp hat deinen Antrag geprüft und wir freuen uns")
      expect(mail.body).to include("<a href=\"http://test.host/groups/380959420/people/600001\">SAC-Portal</a>")
    end

    it "does consider person language when sending" do
      person.update!(language: :fr)
      expect(mail.body).to match("Bonjour Edmund,")
    end
  end

  describe "reject" do
    let(:mail) { described_class.reject(person, group) }

    it "sends confirmation email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "SAC Eintritt Antragsablehnung"
      expect(mail.bcc).to include "mv@sac-cas.ch"
      expect(mail.body).to match("Hallo Edmund,")
      expect(mail.body).to match("Die SAC Blüemlisalp hat deinen Antrag geprüft. Leider müssen wir dir mitteilen")
    end
  end
end
