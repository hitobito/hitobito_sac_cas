# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::TourReportMailer do
  let(:section) { groups(:bluemlisalp) }
  let(:event) { events(:section_tour) }
  let(:report) { event_reports(:section_tour_report) }
  let(:recipient) { people(:mitglied) }

  before do
    CustomContent.init_section_specific_contents(section)
    report.remarks = "Ich habe keine Anmerkungen aber will trotzdem etwas sagen."
  end

  describe "submitted" do
    let(:mail) { described_class.submitted(report, [recipient]) }

    it "sends email to recipients" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Tourenrapport eingereicht: #{event.name}")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{recipient.id})",
        "hat den Tourenrapport zur Tour \"#{event.name} (#{event.id})\" zur Freigabe eingereicht"
      )
    end
  end

  describe "rejected" do
    let(:mail) { described_class.rejected(report, recipient) }

    it "sends email to recipient" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Tourenrapport abgelehnt: #{event.name}")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{recipient.id})",
        "hat den Tourenrapport zur Tour \"#{event.name} (#{event.id})\" " \
        "abgelehnt und zur Korrektur an dich zurückgewiesen",
        "Bemerkungen: #{report.remarks}"
      )
    end
  end

  describe "approved" do
    let(:mail) { described_class.approved(report, recipient) }

    it "sends email to recipient" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Tourenrapport zur Auszahlung freigegeben: #{event.name}")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{recipient.id})",
        "hat den Tourenrapport zur Tour \"#{event.name} (#{event.id})\" zur Auszahlung freigegeben"
      )
    end
  end

  describe "payout_rejected" do
    let(:mail) { described_class.payout_rejected(report, recipient) }

    it "sends email to recipient" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Tourenrapport Auszahlung abgelehnt: #{event.name}")
      expect(mail.body.to_s).to include(
        "Hallo Edmund Hillary (#{recipient.id})",
        "hat die Auszahlung des Tourenrapports zur Tour \"#{event.name} (#{event.id})\" " \
        "abgelehnt und zur Korrektur an dich zurückgewiesen",
        "Bemerkungen: #{report.remarks}"
      )
    end
  end

  describe "payout_recorded" do
    let(:mail) { described_class.payout_recorded(report, recipient) }

    it "sends email to recipient" do
      expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
      expect(mail.subject).to eq("Tourenrapport Auszahlung erfasst: #{event.name}")
    end
  end
end
