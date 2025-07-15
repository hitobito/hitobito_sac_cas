# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::CanceledMailer do
  let(:event) { Fabricate(:sac_open_course, number: 123).tap { |c| c.update_attribute(:state, :canceled) } }
  let(:participation) { event.participations.create!(person: people(:mitglied)) }

  before { Group.root.update!(course_admin_email: "admin@example.com") }

  [["minimum_participants", "Grund dafür ist eine zu geringe Teilnehmerzahl."],
    ["no_leader", "Grund dafür ist der Ausfall der Kursleitung."],
    ["weather", "Grund dafür ist das Wetterrisiko."]].each do |canceled_reason|
    reason, reason_text = canceled_reason

    context reason do
      let(:leader_emails) { %w[leader@example.com assistant@example.com] }
      let(:mail) { described_class.public_send(reason, participation, leader_emails) }

      it "sends email to course leader" do
        expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
        expect(mail.cc).to match_array(%w[leader@example.com assistant@example.com])
        expect(mail.bcc).to match_array(["admin@example.com"])
        expect(mail.body.to_s).to include(
          "Hallo Edmund,",
          "Der Kurs Eventus (Nummer: 123) wurde leider abgesagt.",
          reason_text
        )
      end
    end
  end
end
