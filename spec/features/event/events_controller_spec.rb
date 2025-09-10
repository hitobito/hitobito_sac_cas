# frozen_string_literal: true

#  Copyright (c) 2012-2024, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe EventsController, js: true do
  let(:admin) { people(:admin) }
  let(:event) do
    event = Fabricate(:course, kind: event_kinds(:ski_course), groups: [groups(:root)])
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end

  context "event_questions" do
    it "orders event questions alphabetically on edit page" do
      Event::Question.where(event_id: nil).second.update!(question: "Aaa question?")

      sign_in(admin)
      visit edit_group_event_path(group_id: event.groups.first.id, id: event.id)
      click_on "Anmeldeangaben"
      expect(find("#event_application_questions_attributes_0_question+p").text).to eq "Aaa question?"
      expect(find("#event_application_questions_attributes_1_question+p").text).to eq "AHV-Nummer?"
    end
  end
end
