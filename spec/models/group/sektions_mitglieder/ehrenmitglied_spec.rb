# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
require_relative "../shared_examples_mitglied_role_required"
require_relative "../shared_examples_mitglied_dependant_destroy"

describe Group::SektionsMitglieder::Ehrenmitglied do
  it_behaves_like "Mitglied role required"
  it_behaves_like "Mitglied dependant destroy"

  describe "active membership validations" do
    let(:member) { people(:mitglied) }

    before do
      travel_to("2024-06-01")
      member.roles.first.update!(start_on: "2024-01-01", end_on: "2024-12-01")
      member.roles.last.destroy!
    end

    it "creates role if membership role covers all days" do
      expect do
        member.roles.create!(type: described_class, group: member.groups.first,
          start_on: "2024-04-01", end_on: "2024-12-01")
      end.to change { member.roles.count }.by(1)
    end

    it "is invalid if membership doesn't covers all days" do
      expect do
        member.roles.create!(type: described_class, group: member.groups.first,
          start_on: "2023-12-31", end_on: "2024-04-01")
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
