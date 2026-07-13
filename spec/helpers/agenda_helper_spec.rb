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

  before do
    tour.update_column(:state, :published)
    tour.dates.update_all(start_at: 1.month.from_now)
  end

  it "is true when a future tour with booking info exists" do
    expect(helper.show_places_available_filter?(group)).to be_truthy
  end

  it "is false without a future tour with booking info turned on" do
    tour.update!(display_booking_info: false)
    expect(helper.show_places_available_filter?(group)).to be_falsey
  end

  it "is false for a past tour" do
    tour.dates.update_all(start_at: 1.month.ago)
    expect(helper.show_places_available_filter?(group)).to be_falsey
  end

  it "is false when the tour state is draft" do
    tour.update_column(:state, :draft)
    expect(helper.show_places_available_filter?(group)).to be_falsey
  end
end
