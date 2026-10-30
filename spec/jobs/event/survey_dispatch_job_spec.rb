# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Event::SurveyDispatchJob do
  let(:course) { events(:top_course) }
  let(:client) { instance_double(Events::Courses::SurveyHero::Client) }

  before do
    course.update!(survey_hero_survey_key: "5367281", survey_hero_collector_key: "8294016")
    course.update_column(:state, :ready)
    allow(Events::Courses::SurveyHero::Client).to receive(:new).and_return(client)
    allow(client).to receive(:copy_collector).and_return("https://www.umfrageonline.com/c/abc")
  end

  it "dispatches survey of course" do
    expect { described_class.new(course.id).perform }
      .to have_enqueued_mail(Event::CourseParticipationMailer, :survey).twice

    expect(course.reload.link_survey).to start_with "https://www.umfrageonline.com/c/abc?"
  end

  it "does nothing for deleted course" do
    job = described_class.new(course.id)
    course.destroy!

    expect { job.perform }.not_to have_enqueued_mail
    expect(client).not_to have_received(:copy_collector)
  end
end
