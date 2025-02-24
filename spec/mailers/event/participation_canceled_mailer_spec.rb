# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ParticipationCanceledMailer do
  let(:event) { Fabricate(:sac_open_course) }
  let(:participation) { event.participations.create!(person: people(:mitglied)) }
  let(:mail) { described_class.confirmation(participation) }

  before { Group.root.update!(course_admin_email: "admin@example.com") }

  it "sends to email addresses of participant" do
    expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
    expect(mail.bcc).to match_array(["admin@example.com"])
    expect(mail.body.to_s).to include(
      "Hallo Edmund,",
      "Deine Abmeldung für den Kurs Eventus (Nummer: #{event.number}) wurde bestätigt."
    )
  end
end
