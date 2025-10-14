# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ApplicationClosedMailer do
  let(:event) {
    Fabricate(:sac_open_course).tap { |c|
   c.update_attribute(:state, :assignment_closed) # rubocop:todo Layout/IndentationWidth
    }
  }
  let(:mail) { described_class.notice(event) }

  before { Group.root.update!(course_admin_email: "admin@example.com") }

  it "sends to email addresses of course admin" do
    expect(mail.to).to match_array(["admin@example.com"])
    expect(mail.body.to_s).to include(
      "Lieber Kursadmin,",
      "Die Anmeldung für den Kurs Eventus (Nummer: #{event.number}) wurde abgeschlossen."
    )
  end
end
