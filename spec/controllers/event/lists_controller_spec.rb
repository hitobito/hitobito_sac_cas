#  Copyright (c) 2025, SAC CAS. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Event::ListsController do
  before { sign_in(user) }

  let(:user) { people(:mitglied) }

  describe "GET #events" do
    it "populates events without tours and courses" do
      regular_event = create_event(:bluemlisalp)
      _tour = create_event(:bluemlisalp, type: :sac_tour)
      ortsgruppe = create_event(:bluemlisalp_ortsgruppe_ausserberg)
      ortsgruppe.update_column(:state, :published)
      _course = create_event(:root, type: :sac_course)

      get :events

      expect(assigns(:grouped_events).values).to eq [[regular_event]]
    end
  end

  describe "GET #tours" do
    it "populates tours in group_hierarchy, order by start_at" do
      stammsektion = create_event(:bluemlisalp, type: :sac_tour, start_at: 2.months.from_now)
      stammsektion.update_column(:state, :published)
      zusatzsektion = create_event(:matterhorn, type: :sac_tour)
      zusatzsektion.update_column(:state, :published)
      _draft = create_event(:bluemlisalp, type: :sac_tour, start_at: 5.months.from_now)
      ortsgruppe = create_event(:bluemlisalp_ortsgruppe_ausserberg, type: :sac_tour)
      ortsgruppe.update_column(:state, :published)
      _kurs = create_event(:root, type: :sac_course)
      _regular_event = create_event(:bluemlisalp)

      get :tours

      expect(assigns(:tours).values).to eq [[zusatzsektion], [stammsektion]]
    end
  end

  def create_event(group, hash = {})
    hash = {start_at: 4.days.from_now, type: :event}.merge(hash)
    event = Fabricate(hash[:type], groups: [groups(group)])
    event.dates.create(start_at: hash[:start_at], finish_at: hash[:finish_at])
    event
  end
end
