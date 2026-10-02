# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Events::Filter::AgendaType do
  let(:base_scope) { Event.where(id: all_events.map(&:id)) }

  around do |example|
    travel_to(Time.zone.local(2026, 1, 1)) { example.run }
  end

  def filter(*values)
    described_class.new(:agenda_type, {values: values})
  end

  def build_tour(state, **attrs)
    counts = attrs.extract!(:participant_count)
    Fabricate(:sac_tour, **attrs).tap do |tour|
      tour.update_columns(state: state, **counts)
    end
  end

  let!(:regular_tour) { Fabricate(:sac_tour) }
  let!(:subito_tour) { Fabricate(:sac_tour, subito: true) }
  let!(:regular_event) { Fabricate(:event) }

  let(:all_events) do
    [regular_tour, subito_tour, regular_event]
  end

  describe "#blank?" do
    it "is blank without any value" do
      expect(filter).to be_blank
      expect(filter("")).to be_blank
    end

    it "is blank for a value that is not an agenda types" do
      expect(filter("bogus")).to be_blank
    end

    it "is present for a known type" do
      expect(filter("regular_event")).to be_present
    end
  end

  describe "#apply" do
    it "returns regular tours" do
      expect(filter("regular_tour").apply(base_scope))
        .to contain_exactly(regular_tour)
    end

    it "returns subito tours" do
      expect(filter("subito_tour").apply(base_scope))
        .to contain_exactly(subito_tour)
    end

    it "returns regular events" do
      expect(filter("regular_event").apply(base_scope)).to contain_exactly(regular_event)
    end

    it "combines several statuses" do
      expect(filter("subito_tour", "regular_event").apply(base_scope))
        .to contain_exactly(subito_tour, regular_event)
    end

    it "does not restrict the scope when blank" do
      expect(filter.apply(base_scope)).to match_array(all_events)
    end
  end
end
