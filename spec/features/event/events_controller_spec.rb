# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe EventsController, js: true do
  let(:event) do
    event = Fabricate(:sac_course, kind: event_kinds(:ski_course))
    event.update_column(:state, :application_open)
    Fabricate(:event_participation, event: event, person: person, price: 20, price_category: 1)
    event.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    event
  end

  let(:event_path) { group_event_path(group_id: event.group_ids.first, id: event.id) }

  let(:person) { people(:admin) }

  it "can cancel event" do
    sign_in(person)

    visit event_path
    find("a.dropdown-menu", text: "Publiziert", wait: 2).click
    find('ul[role="menu"] li', text: "Absagen", wait: 2).click

    select "Alle Teilnehmenden per E-Mail über Absage informieren"
    click_on "Definitiv absagen"
    accept_confirm do
      expect do
        perform_enqueued_jobs
      end.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end
end
