# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Group::SektionsMitglieder::Mitglied do
  context 'validations' do
    context 'allows only one active mitglied role at a time' do
      it 'is enforced if the role is active now' do
        existing_role = Fabricate(
          Group::SektionsMitglieder::Mitglied.name,
          group: groups(:bluemlisalp_mitglieder),
          created_at: 1.year.ago
        )

        new_role = Fabricate.build(
          :'Group::SektionsMitglieder::Mitglied',
          person: existing_role.person,
          group: existing_role.group
        )

        expect(new_role).not_to be_valid

        existing_role.update!(deleted_at: 1.month.ago)

        expect(new_role).to be_valid
      end

      it 'is not enforced if the role is expired' do
        existing_role = Fabricate(
          Group::SektionsMitglieder::Mitglied.name,
          group: groups(:bluemlisalp_mitglieder),
          created_at: 1.year.ago,
          delete_on: 1.year.from_now
        )

        new_role = Fabricate.build(
          :'Group::SektionsMitglieder::Mitglied',
          person: existing_role.person,
          group: existing_role.group,
          created_at: 2.month.ago,
          delete_on: 1.day.ago
        )

        expect(new_role).to be_valid
      end
    end
  end
end
