# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe EventsController, js: true do
  include ActiveJob::TestHelper

  let!(:event) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course))
      .tap { |e| e.update_column(:state, :application_open) }
      .tap { |e| e.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago) }
  end

  let!(:participation) do
    Fabricate(Event::Role::Participant.sti_name, participation: Fabricate(:event_participation, event:, person:)).participation.tap { _1.reload }
  end

  let(:event_path) { group_event_path(group_id: event.group_ids.first, id: event.id) }

  let(:person) { people(:admin) }

  describe "canceling event" do
    before do
      sign_in(person)
      visit event_path
      click_on "Publiziert" # open dropdown
      click_on "Absagen"
      select "Wetterrisiko"
    end

    it "may cancel without sending emails" do
      click_on "Definitiv Absagen"
      perform_enqueued_jobs do
        expect do
          accept_confirm
        end.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    it "may cancel and send emails" do
      check "Alle Teilnehmenden per E-Mail über Absage informieren"
      click_on "Definitiv Absagen"
      perform_enqueued_jobs do
        expect do
          accept_confirm
        end.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end
end
