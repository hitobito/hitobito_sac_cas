# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Roles::Termination do
  context 'call' do
    let(:person) { people(:mitglied) }
    let(:role) { roles(:mitglied) }

    let(:other_sektion_mitglieder) do
      Group::Sektion.
        create!(name: 'other_sektion', parent: groups(:root), foundation_year: Date.today.year).
        children.
        find_by(type: 'Group::SektionsMitglieder')
    end

    let!(:other_sektion_role) do
      Group::SektionsMitglieder::Mitglied.create!(person: role.person,
                                                  group: other_sektion_mitglieder)
    end

    let(:terminate_on) { 1.month.from_now.to_date }

    let(:subject) { described_class.new(role: role, terminate_on: terminate_on) }


    context '#affected_roles' do
      context 'for a mitglied role' do
        it 'in the primary group returns the role and all other mitglied roles of the person' do
          assert role.group_id == role.person.primary_group_id

          expect(subject.affected_roles).to eq [role, other_sektion_role]
        end

        it 'not in the primary group returns only the role' do
          role.person.update(primary_group_id: other_sektion_mitglieder.id)

          expect(subject.affected_roles).to eq [role]
        end
      end

      context 'for a non-mitglied role' do
        let(:role) do
          Group::SektionsNeuanmeldungenNv::Neuanmeldung.create!(person: person,
                                                                group: groups(:bluemlisalp_neuanmeldungen_nv))
        end

        it 'in the primary group returns only the role' do
          person.update!(primary_group_id: role.group_id)

          expect(subject.affected_roles).to eq [role]
        end

        it 'not in the primary group returns only the role' do
          person.update!(primary_group_id: other_sektion_role.group_id)

          expect(subject.affected_roles).to eq [role]
        end
      end

    end

    context '#call' do
      it 'when valid terminates affected_roles and returns true' do
        expect(subject.affected_roles).to eq [role, other_sektion_role]
        expect(subject).to be_valid

        expect do
          expect(subject.call).to eq true
        end.
          to change { role.reload.terminated? }.from(false).to(true).
          and change { role.reload.delete_on }.from(nil).to(terminate_on).
          and change { other_sektion_role.reload.terminated? }.from(false).to(true).
          and change { other_sektion_role.reload.delete_on }.from(nil).to(terminate_on)
      end

      it 'when invalid does not terminate affected_roles and return false' do
        allow(subject).to receive(:valid?).and_return(false)
        expect do
          expect(subject.call).to eq false
        end.
          to not_change { role.reload.terminated? }.from(false).
          and not_change { role.reload.delete_on }.from(nil).
          and not_change { other_sektion_role.reload.terminated? }.from(false).
          and not_change { other_sektion_role.reload.delete_on }.from(nil)
      end
    end
  end
end
