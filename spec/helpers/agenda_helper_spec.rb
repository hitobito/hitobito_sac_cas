# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe AgendaHelper do
  let(:group) { groups(:bluemlisalp) }
  let(:tour) { events(:section_tour) }
  let(:course) { events(:top_course) }

  describe "#tour_accent_color" do
    it "is the color of the first main activity" do
      expect(helper.tour_accent_color(tour)).to eq "#237100"
    end

    it "is nil for an event that is not a tour" do
      expect(helper.tour_accent_color(course)).to be_nil
    end
  end

  describe "#agenda_activity_icon" do
    let(:activity) { event_activities(:wanderweg) }

    it "is nothing as long as the main activity has no icon" do
      expect(helper.agenda_activity_icon(activity)).to be_nil
    end

    it "inlines an uploaded svg, so that it takes the badge colour" do
      activity.parent.icon.attach(fixture_file_upload("icon.svg", "image/svg+xml"))

      markup = helper.agenda_activity_icon(activity)
      expect(markup).to include 'class="agenda-activity-icon"'
      expect(markup).to include 'class="agenda-icon"'
      expect(markup).to include "currentColor"
      expect(markup).not_to include "<img"
    end

    it "links an uploaded raster icon, which cannot take the badge colour" do
      activity.parent.icon.attach(fixture_file_upload("icon.png", "image/png"))

      dom = Capybara::Node::Simple.new(helper.agenda_activity_icon(activity))
      expect(dom).to have_css ".agenda-activity-icon img.agenda-icon"
      expect(dom.find("img")[:src]).to include "icon.png"
    end
  end

  describe "#tour_activity_requirements" do
    it "contains requirements of one activity" do
      expect(helper.tour_activity_requirements(tour)).to eq(
        event_activities(:wanderweg) => event_technical_requirements(:wandern_t3, :wandern_t4)
      )
    end
  end

  describe "#tour_price_categories" do
    it "labels every price the tour charges" do
      expect(helper.tour_price_categories(tour)).to eq [
        "Sektionsmitglieder CHF 50",
        "SAC-Mitglieder CHF 60",
        "Nicht-Mitglieder CHF 80"
      ]
    end

    it "is empty for an event that is not a tour" do
      expect(helper.tour_price_categories(course)).to eq []
    end
  end

  describe "#agenda_date_labels" do
    it "formats every date of the event with its weekday" do
      tour.dates.update_all(start_at: Time.zone.local(2026, 3, 2), finish_at: nil)

      expect(helper.agenda_date_labels(tour.reload))
        .to eq ["<span class=\"text-nowrap\">Mo 02.03.2026</span>"]
    end
  end

  describe "#agenda_participant_count" do
    before { tour.update!(display_booking_info: true, participant_count: 3) }

    it "combines the booked places with the limit" do
      expect(helper.agenda_participant_count(tour)).to eq "3/30"
    end

    it "is just the count without a limit" do
      tour.maximum_participants = nil
      expect(helper.agenda_participant_count(tour)).to eq "3"
    end

    it "is nil when the event does not publish its booking info" do
      tour.display_booking_info = false
      expect(helper.agenda_participant_count(tour)).to be_nil
    end
  end

  describe "#agenda_max_participants_label" do
    before { tour.update!(display_booking_info: false, maximum_participants: 30) }

    it "names the limit" do
      expect(helper.agenda_max_participants_label(tour)).to eq "Max. 30 Teilnehmende"
    end

    it "is nil when the event publishes its booking info instead" do
      tour.display_booking_info = true
      expect(helper.agenda_max_participants_label(tour)).to be_nil
    end

    it "is nil without a limit" do
      tour.maximum_participants = 0
      expect(helper.agenda_max_participants_label(tour)).to be_nil
    end
  end

  describe "#agenda_status_badge" do
    it "is a badge carrying the status as a class" do
      tour.update_column(:state, :canceled)

      expect(helper.agenda_status_badge(tour))
        .to eq '<span class="agenda-status-badge agenda-status-canceled">Abgesagt</span>'
    end

    it "is nil for an event type without an agenda status" do
      expect(helper.agenda_status_badge(events(:top_event))).to be_nil
    end
  end

  describe "#agenda_outline_badge" do
    it "renders badge with tooltip" do
      expect(helper.agenda_outline_badge(tour.target_groups.first)).to eq(
        '<span class="agenda-badge-outline" title="Kinderprogramm" data-bs-toggle="tooltip" ' \
         'data-bs-placement="bottom">Kinder (KiBe)</span>'
      )
    end
  end

  describe "#agenda_apply_button" do
    around { |example| travel_to(Time.zone.local(2026, 1, 15)) { example.run } }

    before do
      tour.update_column(:state, :published)
      tour.update!(application_opening_at: Time.zone.local(2025, 12, 1),
        application_closing_at: Time.zone.local(2026, 2, 1),
        display_booking_info: true, maximum_participants: 30, participant_count: 3)
    end

    it "invites an application while places are left" do
      expect(helper.agenda_apply_button(tour, group)).to include ">Anmelden</a>"
      expect(helper.agenda_apply_button(tour, group))
        .to include %(href="/de/groups/#{group.id}/events/#{tour.id}/participations/contact_data")
    end

    it "offers the waiting list once the tour is full" do
      tour.update!(participant_count: 30)

      expect(helper.agenda_apply_button(tour, group)).to include ">Warteliste</a>"
    end

    it "invites an application for a full tour that hides its booking info" do
      tour.update!(participant_count: 30, display_booking_info: false)

      expect(helper.agenda_apply_button(tour, group)).to include ">Anmelden</a>"
    end

    it "is nil once the application period is over" do
      tour.update!(application_opening_at: Time.zone.local(2025, 11, 1),
        application_closing_at: Time.zone.local(2025, 12, 1))

      expect(helper.agenda_apply_button(tour, group)).to be_nil
    end
  end

  describe "#agenda_application_deadline" do
    around { |example| travel_to(Time.zone.local(2026, 1, 15)) { example.run } }

    before do
      tour.update_column(:state, :published)
      tour.update!(application_opening_at: Time.zone.local(2025, 12, 1),
        application_closing_at: Time.zone.local(2026, 2, 1))
    end

    it "is the closing date while the application is possible" do
      expect(helper.agenda_application_deadline(tour))
        .to eq({label: "Anmeldeschluss", value: "01.02.2026"})
    end

    it "is the opening date before the application opens" do
      tour.update!(application_opening_at: Time.zone.local(2026, 6, 1),
        application_closing_at: Time.zone.local(2026, 7, 1))

      expect(helper.agenda_application_deadline(tour))
        .to eq({label: "Anmeldebeginn", value: "01.06.2026"})
    end

    it "is nil once the application period is over" do
      tour.update!(application_opening_at: Time.zone.local(2025, 11, 1),
        application_closing_at: Time.zone.local(2025, 12, 1))

      expect(helper.agenda_application_deadline(tour)).to be_nil
    end
  end

  describe "#agenda_info_block" do
    # Note that the `target`/`rel` the helper passes to safe_auto_link never
    # survive: simple_format sanitizes with Rails' default allow-list, which
    # permits href but neither target nor rel.
    it "auto-links urls" do
      expect(helper.agenda_info_block("see https://example.com now"))
        .to eq '<p>see <a target="_blank" href="https://example.com">https://example.com</a> now</p>'
    end
  end

  describe "#person_initials" do
    it "takes the first letter of the first two words" do
      expect(helper.person_initials(people(:admin))).to eq "AA"
    end
  end

  describe "#event_leader_participations" do
    it "includes leaders but not plain participants" do
      leader = Fabricate(:event_participation, event: tour, participant: people(:mitglied))
      Fabricate(Event::Role::Leader.name.to_sym, participation: leader)
      participant = Fabricate(:event_participation, event: tour, participant: people(:admin))
      Fabricate(Event::Role::Participant.name.to_sym, participation: participant)

      expect(helper.event_leader_participations(tour)).to eq [leader]
    end
  end
end
