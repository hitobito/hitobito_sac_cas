# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Memberships::TerminateAboMagazinAbonnentMailer do
  let(:person) { people(:mitglied) }
  let(:today) { Time.zone.today }

  subject { mail.parts.first.body }

  describe "terminate abonnent" do
    let(:mail) { described_class.terminate_abonnent(person, today) }

    it "sends confirmation email to person" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Kündigung Die Alpen"
      expect(mail.body).to match("Hallo Edmund Hillary,")
      expect(mail.body).to match("Die Kündigung der Die Alpen wurde per #{I18n.l(today)} vorgenommen.")
    end

    it "sends email in language of person" do
      subject = "Résiliation Les Alpes"
      body = <<-TEXT
        Bonjour {person-name},
        La résiliation de Die Alpen a été effectuée via {terminate-on}.
        Salutations sportives,
      TEXT
      I18n.with_locale(:fr) do
        CustomContent.get(Memberships::TerminateAboMagazinAbonnentMailer::TERMINATE_ABONNENT)
          .update!(label: subject, subject: subject, body: body,
            body_de: "{person-name}{terminate-on}")
      end
      person.update!(language: :fr)

      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq "Résiliation Les Alpes"
      expect(mail.body).to match("Bonjour Edmund Hillary,")
      expect(mail.body).to match("La résiliation de Die Alpen a été effectuée via #{I18n.l(today)}.")
    end
  end
end
