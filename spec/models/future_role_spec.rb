# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe FutureRole do
  context "#start_on" do
    it "returns convert_on" do
      role = FutureRole.new(convert_on: 42.days.from_now.to_date)
      expect(role.start_on).to eq role.convert_on
    end
  end

  context "#end_on" do
    it "returns end of year after convert_on" do
      role = FutureRole.new(convert_on: 1.year.from_now.to_date)
      expect(role.end_on).to eq role.convert_on.end_of_year
    end
  end

  context "#validate_target_type?" do
    before do
      stub_const("TargetRole", Class.new(Role))
      stub_const("TargetGroup", Class.new(Group) do
        self.role_types = Role.all_types
      end)
    end

    let(:group) { TargetGroup.new }

    it "returns true if convert_to is a SacCas::MITGLIED_ROLES" do
      SacCas::MITGLIED_AND_NEUANMELDUNG_ROLES.each do |role_type|
        role = FutureRole.new(convert_to: role_type.sti_name, group: group)
        expect(role.validate_target_type?).to eq(true),
          "was unexpectedly false for #{role_type.sti_name}"
      end
    end

    it "returns false if convert_to is not a SacCas::MITGLIED_AND_NEUANMELDUNG_ROLES" do
      (Role.all_types - SacCas::MITGLIED_AND_NEUANMELDUNG_ROLES).each do |role_type|
        role = FutureRole.new(convert_to: role_type.sti_name, group: group)
        expect(role.validate_target_type?).to eq(false),
          "was unexpectedly true for #{role_type.sti_name}"
      end
    end
  end

  describe "#to_s" do
    it "delegates to new role" do
      role = FutureRole.new(
        person: Fabricate(:person),
        convert_to: "Group::SektionsMitglieder::Mitglied",
        convert_on: Time.zone.today,
        group: groups(:bluemlisalp_mitglieder)
      )

      new_role_double = instance_double(Role)
      expect(new_role_double).to receive(:to_s).and_return("new role")
      allow(role).to receive(:build_new_role).and_return(new_role_double)

      expect(role.to_s).to eq "new role"
    end
  end

  context "beitragskategorie" do
    it "gets set for mitglied role" do
      role = FutureRole.new(
        person: Fabricate(:person),
        convert_to: "Group::SektionsMitglieder::Mitglied",
        convert_on: Time.zone.today,
        group: groups(:bluemlisalp_mitglieder)
      )

      expect(SacCas::Beitragskategorie::Calculator).to receive(:new)
        .with(role.person, reference_date: role.convert_on)
        .at_least(:once)
        .and_call_original

      expect { role.validate }.to change { role.beitragskategorie }.from(nil).to("adult")
    end

    it "does not get set for non-mitglied role" do
      role = FutureRole.new(
        person: Fabricate(:person),
        convert_to: "Group::Geschaeftsstelle::Mitarbeiter",
        convert_on: Time.zone.today,
        group: groups(:geschaeftsstelle)
      )

      expect(SacCas::Beitragskategorie::Calculator).not_to receive(:new)

      expect { role.validate }.not_to change { role.beitragskategorie }.from(nil)
    end
  end
end
