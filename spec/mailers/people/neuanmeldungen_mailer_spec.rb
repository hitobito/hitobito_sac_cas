# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::NeuanmeldungenMailer do
  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp) }

  context "#approve" do
    let(:mail) { described_class.approve(person, group.layer_group) }

    it "sends confirmation email to person" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include "mv@sac-cas.ch"
      expect(mail.subject).to eq("SAC Eintritt Antragsbestätigung")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Die SAC Blüemlisalp hat deinen Antrag geprüft und wir freuen uns",
        "<a href=\"http://test.host/groups/380959420/people/600001\">SAC-Portal</a>"
      )
    end

    it "considers person's language when sending" do
      CustomContent.get(People::NeuanmeldungenMailer::APPROVED)
        .update(locale: :fr, label: "lal", subject: "Acceptee", body: "Bonjour")
      person.update!(language: :fr)
      expect(mail.subject).to eq("Acceptee")
      expect(mail.body.to_s).to include("Bonjour")
    end
  end

  context "#reject" do
    let(:mail) { described_class.reject(person, group.layer_group) }

    it "sends confirmation email to person" do
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include "mv@sac-cas.ch"
      expect(mail.subject).to eq("SAC Eintritt Antragsablehnung")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Die SAC Blüemlisalp hat deinen Antrag geprüft. Leider müssen wir dir mitteilen"
      )
    end

    it "considers person's language when sending" do
      CustomContent.get(People::NeuanmeldungenMailer::REJECTED)
        .update(locale: :fr, label: "lal", subject: "Rejetée", body: "Bonjour")
      person.update!(language: :fr)
      expect(mail.subject).to eq("Rejetée")
      expect(mail.body.to_s).to include("Bonjour")
    end

    it "sends confirmation email to deleted person" do
      person.delete
      expect(mail.to).to eq(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include "mv@sac-cas.ch"
      expect(mail.subject).to eq("SAC Eintritt Antragsablehnung")
      expect(mail.body.to_s).to include(
        "Hallo Edmund,",
        "Die SAC Blüemlisalp hat deinen Antrag geprüft. Leider müssen wir dir mitteilen"
      )
    end
  end
end
