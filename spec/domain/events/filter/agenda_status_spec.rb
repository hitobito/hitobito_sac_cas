# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Events::Filter::AgendaStatus do
  let(:base_scope) { Event.where(id: all_events.map(&:id)) }

  around do |example|
    travel_to(Time.zone.local(2026, 1, 1)) { example.run }
  end

  def filter(*values)
    described_class.new(:agenda_status, {values: values})
  end

  def build_tour(state, **attrs)
    counts = attrs.extract!(:participant_count)
    Fabricate(:sac_tour, **attrs).tap do |tour|
      tour.update_columns(state: state, **counts)
    end
  end

  # Tours in a state the agenda never lists at all - their agenda_status is
  # the raw state, which no filter value can select.
  let!(:draft_tour) { build_tour(:draft) }

  let!(:announced_tour) do
    build_tour(:published,
      application_opening_at: Date.new(2026, 2, 1),
      application_closing_at: Date.new(2026, 3, 1))
  end

  let!(:open_tour) do
    build_tour(:published,
      application_opening_at: Date.new(2025, 12, 1),
      application_closing_at: Date.new(2026, 2, 1))
  end

  let!(:open_tour_without_application_window) { build_tour(:published) }

  let!(:full_tour) do
    build_tour(:published,
      application_opening_at: Date.new(2025, 12, 1),
      application_closing_at: Date.new(2026, 2, 1),
      maximum_participants: 2,
      participant_count: 2,
      display_booking_info: true)
  end

  # Full as well, but not publishing its booking info - such a tour keeps
  # advertising an open application rather than a waiting list.
  let!(:full_tour_hiding_booking_info) do
    build_tour(:published,
      application_opening_at: Date.new(2025, 12, 1),
      application_closing_at: Date.new(2026, 2, 1),
      maximum_participants: 2,
      participant_count: 2,
      display_booking_info: false)
  end

  let!(:expired_tour) do
    build_tour(:published,
      application_opening_at: Date.new(2025, 11, 1),
      application_closing_at: Date.new(2025, 12, 1))
  end

  let!(:ready_tour) { build_tour(:ready) }
  let!(:closed_tour) { build_tour(:closed) }
  let!(:canceled_tour) { build_tour(:canceled) }

  # A plain event has no state machine, so only its application window and
  # its places decide the status.
  let!(:open_event) do
    Fabricate(:event,
      application_opening_at: Date.new(2025, 12, 1),
      application_closing_at: Date.new(2026, 2, 1))
  end

  let!(:announced_event) do
    Fabricate(:event, application_opening_at: Date.new(2026, 2, 1))
  end

  let(:all_events) do
    [
      draft_tour,
      announced_tour,
      open_tour,
      open_tour_without_application_window,
      full_tour,
      full_tour_hiding_booking_info,
      expired_tour,
      ready_tour,
      closed_tour,
      canceled_tour,
      open_event,
      announced_event
    ]
  end

  describe "#blank?" do
    it "is blank without any value" do
      expect(filter).to be_blank
      expect(filter("")).to be_blank
    end

    it "is blank for a value that is not an agenda status" do
      expect(filter("bogus")).to be_blank
    end

    it "is present for a known status" do
      expect(filter("application_open")).to be_present
    end
  end

  describe "#apply" do
    it "returns tours and events whose application has not opened yet" do
      expect(filter("published").apply(base_scope))
        .to contain_exactly(announced_tour, announced_event)
    end

    it "returns tours and events currently accepting applications" do
      expect(filter("application_open").apply(base_scope))
        .to contain_exactly(open_tour, open_tour_without_application_window,
          full_tour_hiding_booking_info, open_event)
    end

    it "returns only tours that are full and publish their booking info" do
      expect(filter("application_waiting").apply(base_scope)).to contain_exactly(full_tour)
    end

    it "returns tours whose application window has passed as well as ready ones" do
      expect(filter("application_closed").apply(base_scope))
        .to contain_exactly(expired_tour, ready_tour)
    end

    it "returns tours in a state that maps to itself" do
      expect(filter("closed").apply(base_scope)).to contain_exactly(closed_tour)
      expect(filter("canceled").apply(base_scope)).to contain_exactly(canceled_tour)
    end

    it "combines several statuses" do
      expect(filter("closed", "canceled").apply(base_scope))
        .to contain_exactly(closed_tour, canceled_tour)
    end

    it "never returns a tour in a state the agenda does not publish" do
      described_class::STATUSES.each do |status|
        expect(filter(status).apply(base_scope)).not_to include(draft_tour)
      end
    end

    it "agrees with Event#agenda_status and Events::Tours::State#agenda_status" do
      described_class::STATUSES.each do |status|
        expected = all_events.select { |event| event.agenda_status.to_s == status }

        expect(filter(status).apply(base_scope)).to match_array(expected),
          "expected filter #{status.inspect} to return #{expected.map(&:id).inspect}"
      end
    end

    it "does not restrict the scope when blank" do
      expect(filter.apply(base_scope)).to match_array(all_events)
    end
  end
end
