# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "../shared_examples_mitglied"

describe Group::SektionsMitglieder::Mitglied do
  it_behaves_like "validates Mitglied active period"

  context "household" do
    let(:familienmitglied) { roles(:familienmitglied) }
    let(:familienmitglied2) { roles(:familienmitglied2) }

    it "does destroy household if main person" do
      expect do
        familienmitglied.destroy
      end.to change { familienmitglied.person.reload.sac_family_main_person }.from(true).to(false)
        .and change { Household.new(familienmitglied.person).empty? }.from(false).to(true)
        .and change { familienmitglied.person.reload.primary_group }.from(groups(:bluemlisalp_mitglieder)).to(groups(:matterhorn_mitglieder))
    end

    it "leaves household as as if not main person" do
      expect do
        familienmitglied2.destroy
      end.to not_change { familienmitglied.person.reload.sac_family_main_person }
        .and not_change { Household.new(familienmitglied.person).empty? }
    end
  end
end
