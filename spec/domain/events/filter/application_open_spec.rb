# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Events::Filter::ApplicationOpen do
  let(:base_scope) { Event::Tour.all }
  subject(:filter) { described_class.new(:application_open, params) }

  before do
    Event::Tour.destroy_all
  end

  let!(:no_window_tour) do
    Fabricate(:sac_tour, application_opening_at: nil, application_closing_at: nil)
  end

  let!(:window_open_tour) do
    Fabricate(:sac_tour, application_opening_at: 5.days.ago, application_closing_at: 5.days.from_now)
  end

  let!(:not_yet_window_open_tour) do
    Fabricate(:sac_tour, application_opening_at: 1.days.from_now, application_closing_at: 5.days.from_now)
  end

  let!(:window_closed_tour) do
    Fabricate(:sac_tour, application_opening_at: 5.days.ago, application_closing_at: 1.days.ago)
  end

  context "with filter turned on" do
    let(:params) { {value: 1} }

    it "returns tours whose application window is currently open" do
      expect(filter.blank?).to be_falsey
      result = filter.apply(base_scope)
      expect(result).to include(no_window_tour)
      expect(result).to include(window_open_tour)
      expect(result).not_to include(not_yet_window_open_tour)
      expect(result).not_to include(window_closed_tour)
    end
  end

  context "with filter turned off" do
    let(:params) { {value: 0} }

    it "contains all events" do
      expect(filter.blank?).to be_truthy
      result = filter.apply(base_scope)
      expect(result.count).to eq 2
    end
  end
end
