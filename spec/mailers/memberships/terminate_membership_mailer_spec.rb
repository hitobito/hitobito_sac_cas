# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::TerminateMembershipMailer do
  let(:person) { people(:mitglied) }
  let(:group) { groups(:bluemlisalp) }
  let(:today) { Time.zone.today }

  subject { mail.parts.first.body }

  describe "terminate membership" do
    let(:mail) { described_class.terminate_membership(person, group, today) }

    it "sends confirmation email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include(SacCas::MV_EMAIL)
      expect(mail.bcc).to include("bluemlisalp@sac.ch")
      expect(mail.subject).to eq "Der SAC Austritt wurde per #{I18n.l(today)} vorgenommen"
      expect(mail.body).to match("Hallo Edmund Hillary,")
      expect(mail.body).to match("Der SAC Austritt wurde per #{I18n.l(today)} vorgenommen.")
    end

    it "sends email in language of person" do
      subject = "Résiliation de l’affiliation"
      body = <<-TEXT
        Bonjour {person-name},
        Nous avons pris acte avec regret de ta sortie du CAS. Ton affiliation sera résiliée au {terminate-on}.
        Ta section {sektion-name} sera informée de ta sortie.
        Un grand merci pour ta fidélité envers le Club Alpin Suisse CAS.
        Salutations sportives,
      TEXT
      I18n.with_locale(:fr) do
        CustomContent.get(Memberships::TerminateMembershipMailer::TERMINATE_MEMBERSHIP)
          .update!(label: subject, subject: subject, body: body)
      end
      person.update!(language: :fr)

      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Résiliation de l’affiliation"
      expect(mail.body).to match("Bonjour Edmund Hillary,")
      expect(mail.body).to match("Ton affiliation sera résiliée au #{I18n.l(today)}.")
    end

    it "sends confirmation email to geschaefsstelle if configured" do
      groups(:geschaeftsstelle).update!(email: "geschaeftsstelle@example.com")
      expect(mail.cc).to eq ["geschaeftsstelle@example.com"]
    end
  end

  describe "leave_zusatzsektion" do
    let(:mail) { described_class.leave_zusatzsektion(person, group, today) }

    it "sends confirmation email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.bcc).to include(SacCas::MV_EMAIL)
      expect(mail.bcc).to include("bluemlisalp@sac.ch")
      expect(mail.subject).to eq "Bestätigung Austritt Zusatzsektion"
      expect(mail.body).to match("Hallo Edmund Hillary,")
      expect(mail.body).to match("Der Austritt aus SAC Blüemlisalp wurde per #{I18n.l(today)} vorgenommen.")
    end

    it "sends confirmation email to geschaefsstelle if configured" do
      groups(:geschaeftsstelle).update!(email: "geschaeftsstelle@example.com")
      expect(mail.cc).to eq ["geschaeftsstelle@example.com"]
    end
  end
end
