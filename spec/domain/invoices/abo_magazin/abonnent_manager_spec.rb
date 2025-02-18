# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Invoices::AboMagazin::AbonnentManager do
  let(:abonnent) { roles(:abonnent_alpen) }
  let(:abonnent_person) { people(:abonnent) }
  let(:die_alpen) { groups(:abo_die_alpen) }

  subject { described_class.new(abonnent_person, die_alpen) }

  context "person is abonnent already" do
    it "adds one year to current end_on" do
      end_on_before = abonnent.end_on

      subject.update_abonnent_status

      expect(abonnent.reload.end_on).to eq(end_on_before + 1.year)
    end
  end

  context "person has expired abonnent role" do
    it "does nothing if previous role expired over a year ago" do
      abonnent.update_column(:end_on, 2.years.ago)
      end_on_before = abonnent.end_on
      subject.update_abonnent_status
      expect(abonnent.reload.end_on).to eq end_on_before
    end

    it "creates new role starting today ending one year after previous role" do
      abonnent.update_column(:end_on, 30.days.ago)

      expect { subject.update_abonnent_status }.to change { Role.count }.by(1)
      new_role = abonnent_person.roles.first

      expect(new_role.end_on).to eq(abonnent.end_on + 1.year)
      expect(new_role.start_on).to eq(Time.zone.today)
      expect(new_role.person).to eq(abonnent.person)
      expect(new_role.group).to eq(abonnent.group)
    end
  end

  context "person has neuanmeldungs role" do
    before do
      abonnent.destroy!
      Fabricate(:role, type: Group::AboMagazin::Neuanmeldung.sti_name,
        group: die_alpen,
        person: abonnent_person,
        start_on: 2.days.ago,
        end_on: 30.days.from_now)
    end

    it "creates new role starting today ending one year after previous role" do
      old_role = abonnent_person.roles.first
      subject.update_abonnent_status
      new_role = abonnent_person.roles.first

      expect(old_role.reload.end_on).to eq(Time.zone.yesterday)

      expect(new_role.end_on).to eq(old_role.end_on + 1.year)
      expect(new_role.start_on).to eq(old_role.start_on)
      expect(new_role.person).to eq(old_role.person)
      expect(new_role.group).to eq(old_role.group)
    end
  end

  context "person has expired neuanmeldungs role" do
    before do
      abonnent.destroy!
      Fabricate(:role, type: Group::AboMagazin::Neuanmeldung.sti_name,
        group: die_alpen,
        person: abonnent_person,
        start_on: 60.days.ago,
        end_on: 30.days.ago)
    end

    it "creates new role starting today ending one year after previous role" do
      old_role = abonnent_person.roles.with_inactive.first
      subject.update_abonnent_status
      new_role = abonnent_person.roles.first

      expect(new_role.end_on).to eq(old_role.end_on + 1.year)
      expect(new_role.start_on).to eq(old_role.start_on)
      expect(new_role.person).to eq(old_role.person)
      expect(new_role.group).to eq(old_role.group)
    end
  end
end
