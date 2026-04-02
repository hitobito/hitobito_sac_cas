# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Events::Filter::Sac do
  let(:section) { groups(:matterhorn) }
  let(:base_scope) { section.events.where(type: Event::Tour.sti_name) }

  let!(:subito) do
    Fabricate(:sac_tour,
      groups: [section],
      subito: true)
  end

  let!(:winter) do
    Fabricate(:sac_tour,
      groups: [section],
      season: :winter)
  end

  let!(:summer) do
    Fabricate(:sac_tour,
      groups: [section],
      season: :summer)
  end

  def filter_entries(params)
    described_class.new(:sac, params).apply(base_scope)
  end

  context "with subito filter" do
    it "includes only subito" do
      result = filter_entries(subito: "true")
      expect(result).to match_array([subito])
    end

    it "includes only regular" do
      result = filter_entries(subito: "false")
      expect(result).to match_array([winter, summer])
    end
  end

  context "with season filter" do
    it "includes only summer" do
      result = filter_entries(season: "summer")
      expect(result).to match_array([summer])
    end
  end
end
