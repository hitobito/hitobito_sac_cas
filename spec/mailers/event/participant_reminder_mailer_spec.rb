# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ParticipantReminderMailer do
  let(:event) { Fabricate(:sac_open_course, groups: [groups(:root)]) }
  let!(:participation) { Fabricate(:event_participation, event:, participant: people(:mitglied)) }
  let(:mail) { described_class.reminder(participation) }

  before do
    %w[nil_example no_example yes_example].each do |question|
      event.questions.create!(admin: true, question:, disclosure: :optional)
    end
    event.questions.second.answers.update_all(answer: "no")
    event.questions.third.answers.update_all(answer: "yes")
    Group.root.update!(course_admin_email: "admin@example.com")
  end

  it "sends email to participants with missing answers" do
    expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
    expect(mail.bcc).to match_array(["admin@example.com"])
    expect(mail.subject).to eq("Fehlende Administrationsangaben")
    expect(mail.body.to_s).to include(
      "Hallo Edmund,",
      "Für die Teilnahme an diesem Kurs sind die folgenden Nachweise zu erbringen.",
      "nil_example",
      "no_example"
    )
    expect(mail.body.to_s).not_to include("yes_example")
  end
end
