# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Export::Tabular::Events::Tours::List do
  let(:tour) { events(:section_tour) }
  let(:list) { described_class.new([tour]) }

  it "uses Tours::Row as row class" do
    expect(described_class.row_class).to eq Export::Tabular::Events::Tours::Row
  end

  it "includes the tour specific columns in addition to the base event columns" do
    expect(list.attributes).to include(
      :id, :season, :summit, :elevation, :duration_in_hours, :tourenportal_link, :maps,
      :alternative_route, :additional_info, :leaders, :minimum_participants,
      :price_special, :price_member, :price_regular, :price_description,
      :activities, :target_groups, :fitness_requirement, :technical_requirements, :traits
    )
    # base columns are still present, unchanged
    expect(list.attributes).to include(:name, :group_names, :description, :location,
      :maximum_participants, :teamer_count, :participant_count, :applicant_count)
  end

  it "labels the new columns" do
    labels = list.attribute_labels
    expect(labels[:id]).to eq "Event-ID"
    expect(labels[:elevation]).to eq "Auf-/Abstieg (Hm)"
    expect(labels[:leaders]).to eq "Leitungsteam"
    expect(labels[:price_special]).to eq "Kosten SAC Sektionsmitglied"
    expect(labels[:price_member]).to eq "Kosten SAC-Mitglied (extern)"
    expect(labels[:price_regular]).to eq "Kosten nicht-SAC-Mitglied (Gast)"
    expect(labels[:price_description]).to eq "Kosten Hinweis"
    expect(labels[:minimum_participants]).not_to be_nil
    expect(labels[:activities]).not_to be_nil
    expect(labels[:target_groups]).not_to be_nil
    expect(labels[:fitness_requirement]).not_to be_nil
    expect(labels[:technical_requirements]).not_to be_nil
    expect(labels[:traits]).not_to be_nil
  end

  it "falls back to Event::Tour as model_class when the list is empty" do
    expect(described_class.new([]).send(:model_class)).to eq Event::Tour
  end
end
