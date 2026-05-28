# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::TourApprovalMailer do
  let(:section) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:recipient) { people(:mitglied) }
  let(:updater) { people(:familienmitglied) }

  before do
    CustomContent.init_section_specific_contents(section)
    event.updater = updater
  end

  describe "required" do
    let(:cc_recipient) { people(:admin) }
    let(:mail) { described_class.required(event, [recipient], [cc_recipient]) }

    it "sends email to recipients with cc" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.cc).to match_array([cc_recipient.email])
      expect(mail.subject).to eq("Aktion erforderlich: Tour #{event.name} (#{event.id}) zur Prüfung")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary",
        "#{updater.first_name} #{updater.last_name} (#{updater.id}",
        "hat die Tour #{event.name} (#{event.id}) zur Freigabe weitergeleitet"
      )
    end
  end

  describe "rejected" do
    let(:cc_recipient) { people(:admin) }
    let(:mail) { described_class.rejected(event, recipient, [cc_recipient]) }

    it "sends email to recipient with cc" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.cc).to match_array([cc_recipient.email])
      expect(mail.subject).to eq("Tour #{event.name} (#{event.id}) wurde abgelehnt")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{recipient.id})",
        "#{updater.first_name} #{updater.last_name} (#{updater.id}",
        "hat die Tour #{event.name} (#{event.id}) abgelehnt"
      )
    end
  end

  describe "granted" do
    let(:cc_recipient) { people(:admin) }
    let(:mail) { described_class.granted(event, recipient, [cc_recipient]) }

    it "sends email to recipient with cc" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.cc).to match_array([cc_recipient.email])
      expect(mail.subject).to eq("Tour #{event.name} (#{event.id}) wurde freigegeben")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{recipient.id})",
        "Du kannst die Tour nun in einem nächsten Schritt publizieren."
      )
    end
  end

  describe "self_approved" do
    let(:cc_recipient) { people(:admin) }
    let(:mail) { described_class.self_approved(event, [recipient], [cc_recipient]) }

    it "sends email to recipients with cc" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.cc).to match_array([cc_recipient.email])
      expect(mail.subject).to eq("Tour #{event.name} (#{event.id}) wurde selbst freigegeben")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary",
        "#{updater.first_name} #{updater.last_name} (#{updater.id}",
        "hat die Tour #{event.name} (#{event.id}) selbst freigegeben"
      )
    end
  end
end
