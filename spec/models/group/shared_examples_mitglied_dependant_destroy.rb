# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

shared_examples "Mitglied dependant destroy" do
  before { travel_to("2024-06-01") }

  let(:person) { Fabricate(:person) }
  let!(:mitglied_role) do
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group:, person:, start_on: 1.year.ago)
  end
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:other_group) { groups(:matterhorn_mitglieder) }
  let!(:role) {
    described_class.new(person:, group:, start_on: 1.year.ago,
      end_on: mitglied_role.end_on).tap(&:save!)
  }

  let(:old_enough) { Settings.role.minimum_days_to_archive.days.ago - 1.second }
  let(:not_old_enough) { Settings.role.minimum_days_to_archive.days.ago + 1.second }

  shared_examples "stays untouched with skip_destroy_dependent_roles set" do
    it do
      mitglied_role.skip_destroy_dependent_roles = true
      expect { mitglied_role.destroy(always_soft_destroy: true) }
        .not_to change { role.reload.end_on }
    end
  end

  context "with Mitglied role" do
    it "gets ended if it is old enough" do
      role.update!(created_at: old_enough)
      expect { mitglied_role.destroy(always_soft_destroy: true) }
        .to change { mitglied_role.reload.end_on }.to(Date.current.yesterday)

      expect(role.reload.end_on).to eq(mitglied_role.end_on)
    end

    it "gets hard deleted if it is not old enough" do
      role.update!(created_at: not_old_enough)
      expect { mitglied_role.destroy(always_soft_destroy: true) }
        .to change { mitglied_role.reload.end_on }.to(Date.current.yesterday)

      expect { role.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "gets hard deleted when Mitglied role is hard deleted even if old enough" do
      role.update!(created_at: old_enough)
      mitglied_role.destroy
      expect(Role.with_inactive.where(id: role.id)).not_to exist

      expect { role.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it_behaves_like "stays untouched with skip_destroy_dependent_roles set"
  end

  context "with MitgliedZusatzsektion role" do
    let!(:mitglied_role) do
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name, group: other_group, person:,
        start_on: 1.year.ago)
      Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name, group:, person:,
        start_on: 1.year.ago)
    end

    it "gets ended if it is old enough" do
      role.update!(created_at: old_enough)
      expect { mitglied_role.destroy(always_soft_destroy: true) }
        .to change { mitglied_role.reload.end_on }.to(Date.current.yesterday)

      expect(role.reload.end_on).to eq(mitglied_role.end_on)
    end

    it "gets hard deleted if it is not old enough" do
      role.update!(created_at: not_old_enough)
      mitglied_role.destroy
      expect(Role.with_inactive.where(id: role.id)).not_to exist

      expect { role.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "gets hard deleted when MitgliedZusatzsektion role is hard deleted" do
      mitglied_role.destroy
      expect(Role.with_inactive.where(id: role.id)).not_to exist

      expect { role.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it_behaves_like "stays untouched with skip_destroy_dependent_roles set"
  end
end
