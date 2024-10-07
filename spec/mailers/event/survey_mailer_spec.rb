# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::SurveyMailer do
  let(:event) do
    Fabricate(:sac_open_course,
      link_survey: "https://example.com/survey",
      dates: [Fabricate(:event_date, start_at: 1.week.ago, finish_at: 3.days.ago)])
  end

  let(:participation) { Fabricate(:event_participation, event:, person: people(:mitglied), state: :attended) }
  let(:mail) { described_class.survey(participation) }

  before { event.groups.first.update!(course_admin_email: "admin@example.com") }

  it "sends email to participant" do
    expect(mail.to).to match_array(["e.hillary@hitobito.example.com"])
    expect(mail.bcc).to match_array(["admin@example.com"])
    expect(mail.body.to_s).to include(
      "Hallo Edmund,",
      "wenn du dir einen Moment Zeit nehmen könntest, um an unserer Umfrage teilzunehmen",
      "<a href=\"https://example.com/survey\">https://example.com/survey</a>"
    )
  end
end
