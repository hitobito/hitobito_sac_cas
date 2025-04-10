# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "event state transitions", js: true do
  include ActiveJob::TestHelper

  let!(:event) do
    Fabricate(:sac_course, kind: event_kinds(:ski_course)).tap do |e|
      e.update_column(:state, :application_open)
      e.dates.create!(start_at: 10.days.ago, finish_at: 5.days.ago)
    end
  end

  let!(:participation) do
    Fabricate(:event_participation, event:, person:).tap do |participation|
      Fabricate(Event::Course::Role::Participant.sti_name, participation:)
    end.reload
  end

  let(:person) { people(:admin) }

  describe "canceling event" do
    let(:event_path) { group_event_path(group_id: event.group_ids.first, id: event.id) }

    before do
      sign_in(person)
      visit event_path
      click_on "Publiziert" # open dropdown
      click_on "Absagen"
      select "Wetterrisiko"
    end

    it "may cancel without sending emails" do
      click_on "Definitiv Absagen"
      expect do
        accept_confirm
        expect(page).to have_content "Absagegrund\nWetterrisiko"
      end.not_to have_enqueued_mail(Event::CanceledMailer)
    end

    it "may cancel and send emails" do
      check "Alle Teilnehmenden per E-Mail über Absage informieren"
      click_on "Definitiv Absagen"
      expect do
        accept_confirm
        expect(page).to have_content "Absagegrund\nWetterrisiko"
      end.to have_enqueued_mail(Event::CanceledMailer).once
    end
  end
end
