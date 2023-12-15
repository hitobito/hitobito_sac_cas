# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe :mitglied_no_overlap_validation do

  context 'no overlapping primary memberships' do
    shared_examples 'allows only one active role at a time' do |mitglied_type|
      context "for #{mitglied_type.sti_name}" do
        let(:existing_role) do
          Fabricate(
            mitglied_type.sti_name,
            group: group,
            created_at: Time.zone.parse('2019-01-01'),
            delete_on: Time.zone.parse('2019-12-31')
          )
        end

        it 'allows disjoint active_period' do
          new_role = Fabricate.build(
            mitglied_type.sti_name,
            person: existing_role.person,
            group: existing_role.group,
            created_at: existing_role.delete_on + 1.day,
            delete_on: existing_role.delete_on + 2.days
          )

          expect(new_role).to be_valid

          new_role.delete_on = existing_role.created_at - 1.day
          new_role.created_at = existing_role.created_at - 2.days

          expect(new_role).to be_valid
        end

        it 'denies concurrent active_period for same type in same sektion' do
          new_role = Fabricate.build(
            mitglied_type.sti_name,
            person: existing_role.person,
            group: existing_role.group,
            created_at: existing_role.created_at,
            delete_on: existing_role.delete_on
          )

          expect(new_role).not_to be_valid
          expect(new_role.errors[:person]).to eq [error_message]
        end

        it 'denies concurrent active_period in different sektion' do
          new_role = Fabricate.build(
            mitglied_type.sti_name,
            person: existing_role.person,
            group: other_sektion_group,
            created_at: existing_role.created_at,
            delete_on: existing_role.delete_on
          )

          expect(new_role).not_to be_valid
          expect(new_role.errors[:person]).to eq [error_message]
        end

        it 'denies concurrent active_period for other mitglied types' do
          other_mitglied_types_map.each do |other_type, other_type_group|
            new_role = Fabricate.build(
              other_type.sti_name,
              person: existing_role.person,
              group: other_type_group,
              created_at: existing_role.created_at,
              delete_on: existing_role.delete_on
            )

            expect(new_role).not_to be_valid, "expected #{other_type.sti_name} to be invalid"
            expect(new_role.errors[:person]).to eq [error_message]
          end
        end
      end
    end

    it_behaves_like 'allows only one active role at a time', Group::SektionsMitglieder::Mitglied do
      let(:error_message) { 'ist bereits Mitglied (von 01.01.2019 bis 31.12.2019).' }
      let(:group) { groups(:bluemlisalp_mitglieder) }
      let(:other_sektion_group) { groups(:matterhorn_mitglieder) }
      let(:other_mitglied_types_map) do
        {
          Group::SektionsNeuanmeldungenSektion::Neuanmeldung => groups(:bluemlisalp_neuanmeldungen_sektion),
          Group::SektionsNeuanmeldungenNv::Neuanmeldung => groups(:bluemlisalp_neuanmeldungen_nv)
        }
      end
    end

    it_behaves_like 'allows only one active role at a time', Group::SektionsNeuanmeldungenSektion::Neuanmeldung do
      let(:error_message) { 'hat bereits eine Neuanmeldung (von 01.01.2019 bis 31.12.2019).' }
      let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
      let(:other_sektion_group) { groups(:matterhorn_neuanmeldungen_sektion) }
      let(:other_mitglied_types_map) do
        {
          Group::SektionsMitglieder::Mitglied => groups(:bluemlisalp_mitglieder),
          Group::SektionsNeuanmeldungenNv::Neuanmeldung => groups(:bluemlisalp_neuanmeldungen_nv)
        }
      end
    end

    it_behaves_like 'allows only one active role at a time', Group::SektionsNeuanmeldungenNv::Neuanmeldung do
      let(:error_message) { 'hat bereits eine Neuanmeldung (von 01.01.2019 bis 31.12.2019).' }
      let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
      let(:other_sektion_group) { groups(:matterhorn_neuanmeldungen_nv) }
      let(:other_mitglied_types_map) do
        {
          Group::SektionsMitglieder::Mitglied => groups(:bluemlisalp_mitglieder),
          Group::SektionsNeuanmeldungenSektion::Neuanmeldung => groups(:bluemlisalp_neuanmeldungen_sektion)
        }
      end
    end
  end

  context 'no overlapping memberships per sektion' do
    def create_existing_role(mitglied_type, *attrs)
      Fabricate.build(mitglied_type, *attrs).tap {|p| p.save(validate: false) }
    end

    let(:group) { groups(:bluemlisalp_mitglieder) }

    SacCas::MITGLIED_ROLES.each do |mitglied_type|
      context mitglied_type.sti_name do
        let(:existing_role) do
          create_existing_role(
            mitglied_type.sti_name,
            group: group,
            created_at: Time.zone.parse('2019-01-01'),
            delete_on: Time.zone.parse('2019-12-31')
          )
        end

        (SacCas::MITGLIED_ROLES - [mitglied_type]).each do |other_type|
          context "in same sektion with #{other_type.sti_name}" do
            it "allows disjoint active_period" do
              new_role = Fabricate.build(
                other_type.sti_name,
                person: existing_role.person,
                group: existing_role.group,
                created_at: existing_role.delete_on + 1.day,
                delete_on: existing_role.delete_on + 2.days
              )

              new_role.validate

              expect(new_role.errors[:person]).not_to include(/bereits/)

              new_role.delete_on = existing_role.created_at - 1.day
              new_role.created_at = existing_role.created_at - 2.days
              new_role.validate

              expect(new_role.errors[:person]).not_to include(/bereits/)
            end

            it 'denies concurrent active_period for same type in same sektion' do
              new_role = Fabricate.build(
                other_type.sti_name,
                person: existing_role.person,
                group: existing_role.group,
                created_at: existing_role.created_at,
                delete_on: existing_role.delete_on
              )

              new_role.validate

              expect(new_role.errors[:person]).to include('hat bereits eine Neuanmeldung (von 01.01.2019 bis 31.12.2019).').
                or(include('ist bereits Mitglied (von 01.01.2019 bis 31.12.2019).'))
            end
          end
        end
      end
    end
  end
end
