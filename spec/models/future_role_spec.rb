# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe FutureRole do
  context 'target_type validations' do
    let(:group) { groups(:root) }
    let(:person) { people(:mitglied) }

    before do
      stub_const('TargetRole', Class.new(Role) do
        attr_accessor :target_type_valid
        validates :target_type_valid, presence: true
      end)
      group.class.role_types += [TargetRole]
    end

    after do
      group.class.role_types -= [TargetRole]
    end

    let(:role) do
      Fabricate.build(
        :future_role,
        person: person,
        group: group,
        convert_to: TargetRole.sti_name,
        convert_on: Time.zone.tomorrow
      )
    end

    it 'are checked if validate_target_type? returns true' do
      allow(role).to receive(:validate_target_type?).and_return(true)
      role.validate

      expect(role.errors[:target_type_valid]).to include("muss ausgefüllt werden")
    end

    it 'are skipped if validate_target_type? returns false' do
      allow(role).to receive(:validate_target_type?).and_return(false)
      role.validate

      expect(role.errors[:target_type_valid]).to be_blank
    end
  end

  context '#start_on' do
    it 'returns convert_on' do
      role = FutureRole.new(convert_on: 42.days.from_now.to_date)
      expect(role.start_on).to eq role.convert_on
    end
  end

  context '#end_on' do
    it 'returns end of year after convert_on' do
      role = FutureRole.new(convert_on: 1.year.from_now.to_date)
      expect(role.end_on).to eq role.convert_on.end_of_year
    end
  end

  context '#validate_target_type?' do
    before do
      stub_const('TargetRole', Class.new(Role))
      stub_const('TargetGroup', Class.new(Group) do
        self.role_types = Role.all_types
      end)
    end

    let(:group) { TargetGroup.new }

    it 'returns true if convert_to is a SacCas::MITGLIED_ROLES' do
      SacCas::MITGLIED_ROLES.each do |role_type|
        role = FutureRole.new(convert_to: role_type.sti_name, group: group)
        expect(role.validate_target_type?).to eq(true), "was unexpectedly false for #{role_type.sti_name}"
      end
    end

    it 'returns false if convert_to is not a SacCas::MITGLIED_ROLES' do
      (Role.all_types - SacCas::MITGLIED_ROLES).each do |role_type|
        role = FutureRole.new(convert_to: role_type.sti_name, group: group)
        expect(role.validate_target_type?).to eq(false), "was unexpectedly true for #{role_type.sti_name}"
      end
    end
  end
end
