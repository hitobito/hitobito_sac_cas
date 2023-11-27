# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Roles::Termination do
  context 'call' do
    let(:person) { people(:familienmitglied) }
    let(:role) { roles(:familienmitglied) }

    let(:terminate_on) { 1.month.from_now.to_date }

    let(:subject) { described_class.new(role: role, terminate_on: terminate_on) }


    context '#affected_roles' do
      let(:role) { roles(:mitglied) }

      context 'for a mitglied role' do
        it 'in the primary group returns the role and all other mitglied roles of the person' do
          assert role.group_id == role.person.primary_group_id

          expect(subject.affected_roles).to eq [role, roles(:mitglied_zweitsektion)]
        end

        it 'not in the primary group returns only the role' do
          role.person.update(primary_group_id: roles(:mitglied_zweitsektion).group_id)

          expect(subject.affected_roles).to eq [role]
        end
      end

      context 'for a non-mitglied role' do
        let(:role) do
          Group::SektionsNeuanmeldungenNv::Neuanmeldung.create!(person: person,
                                                                group: groups(:bluemlisalp_neuanmeldungen_nv),
                                                                beitragskategorie: 'einzel')
        end

        it 'in the primary group returns only the role' do
          person.update!(primary_group_id: role.group_id)

          expect(subject.affected_roles).to eq [role]
        end

        it 'not in the primary group returns only the role' do
          expect(person.primary_group_id).not_to eq role.group_id # check precondition

          expect(subject.affected_roles).to eq [role]
        end
      end

    end

    context '#family_member_roles' do
      context 'for a mitglied role' do
        it 'with beitragskategorie=familie returns the family_member roles' do
          expect(role.beitragskategorie).to eq 'familie'

          expect(subject.family_member_roles).to eq [roles(:familienmitglied2),
                                                     roles(:familienmitglied_kind)]
        end

        (::SacCas::Beitragskategorie::Calculator::BEITRAGSKATEGORIEN - ['familie']).each do |category|
          it "with beitragskategorie=#{category} returns empty list" do
            role.beitragskategorie = category

            expect(subject.family_member_roles).to eq []
          end
        end
      end

      context 'for a non-mitglied role' do
        before { person.update!(primary_group_id: groups(:bluemlisalp_neuanmeldungen_nv).id) }
        let(:role) do
          Group::SektionsNeuanmeldungenNv::Neuanmeldung.create!(person: person,
                                                                group: groups(:bluemlisalp_neuanmeldungen_nv),
                                                                beitragskategorie: 'familie')
        end

        it 'returns empty list' do
          expect(subject.family_member_roles).to eq []
        end
      end
    end

    context '#call' do
      context 'affected_roles' do
        let(:role) { roles(:mitglied) }

        it 'get terminated' do
          expect(subject.affected_roles).to eq [role, roles(:mitglied_zweitsektion)]

          expect { subject.call }.
            to change { role.reload.terminated? }.from(false).to(true).
            and change { role.delete_on }.from(nil).to(terminate_on).
            and change {
                  roles(:mitglied_zweitsektion).reload.terminated?
                }.from(false).to(true).
            and change { roles(:mitglied_zweitsektion).delete_on }.from(nil).to(terminate_on)
        end

        it 'dont get terminated if invalid' do
          allow(subject).to receive(:valid?).and_return(false)
          expect do
            expect(subject.call).to eq false
          end.
            to not_change { role.reload.terminated? }.from(false).
            and not_change { role.delete_on }.from(nil).
            and not_change { roles(:mitglied_zweitsektion).reload.terminated? }.from(false).
            and not_change { roles(:mitglied_zweitsektion).delete_on }.from(nil)
        end
      end

      context 'family_member roles' do
        it 'terminates family member roles' do
          expect(subject.family_member_roles).to eq [roles(:familienmitglied2),
                                                     roles(:familienmitglied_kind)]

          expect { subject.call }.
            to change { role.reload.terminated? }.from(false).to(true).
            and change { role.delete_on }.from(nil).to(terminate_on).
            and change { roles(:familienmitglied2).reload.terminated? }.from(false).to(true).
            and change { roles(:familienmitglied2).delete_on }.from(nil).to(terminate_on).
            and change { roles(:familienmitglied_kind).reload.terminated? }.from(false).to(true).
            and change { roles(:familienmitglied_kind).delete_on }.from(nil).to(terminate_on)
        end

        it 'dont get terminated if invalid' do
          allow(subject).to receive(:valid?).and_return(false)
          expect do
            expect(subject.call).to eq false
          end.
            to not_change { role.reload.terminated? }.from(false).
            and not_change { role.delete_on }.from(nil).
            and not_change { roles(:familienmitglied2).reload.terminated? }.from(false).
            and not_change { roles(:mitglied_zweitsektion).delete_on }.from(nil).
            and not_change { roles(:familienmitglied_kind).reload.terminated? }.from(false).
            and not_change { roles(:familienmitglied_kind).delete_on }.from(nil)
        end
      end


    end
  end
end
