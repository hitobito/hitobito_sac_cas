# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Roles::Termination do
  let(:person) { people(:familienmitglied) }
  let(:role) { roles(:familienmitglied) }

  let(:terminate_on) { 1.month.from_now.to_date }

  let(:subject) { described_class.new(role: role, terminate_on: terminate_on) }

  context '#call' do
    context 'role' do
      let(:role) { roles(:mitglied) }

      it 'gets terminated' do
        allow(subject).to receive(:valid?).and_return(true)

        expect do
          expect(subject.call).to eq true
        end.
          to change { role.reload.terminated? }.from(false).to(true).
            and change { role.reload.delete_on }.to(terminate_on)
      end

      it 'gets terminated even if role is invalid' do
        allow_any_instance_of(Role).to receive(:valid?).and_return(false)
        expect(role).to be_invalid

        expect do
          expect(subject.call).to eq true
        end.
          to change { role.reload.terminated? }.from(false).to(true).
            and change { role.reload.delete_on }.to(terminate_on)
      end

      it 'does not get terminated when invalid' do
        allow(subject).to receive(:valid?).and_return(false)

        expect do
          expect(subject.call).to eq false
        end.
          to not_change { role.reload.terminated? }.from(false).
            and not_change { role.reload.delete_on }
      end
    end

    context 'stammsektion' do
      let(:role) { roles(:mitglied) }

      it 'terminates stammsektion and zusatzsektion roles' do
        expect { subject.call }.
          to change { role.reload.terminated? }.from(false).to(true).
          and change { role.delete_on }.to(terminate_on).
          and change {
                roles(:mitglied_zweitsektion).reload.terminated?
              }.from(false).to(true).
          and change { roles(:mitglied_zweitsektion).delete_on }.to(terminate_on)
      end

      it 'dont get terminated if invalid' do
        allow(subject).to receive(:valid?).and_return(false)
        expect do
          expect(subject.call).to eq false
        end.
          to not_change { role.reload.terminated? }.from(false).
          and not_change { role.delete_on }.
          and not_change { roles(:mitglied_zweitsektion).reload.terminated? }.from(false).
          and not_change { roles(:mitglied_zweitsektion).delete_on }
      end
    end

    context 'zusatzsektion' do
      let(:role) { roles(:mitglied_zweitsektion) }

      it 'terminates zusatzsektion roles only' do
        expect { subject.call }.
          to change { role.reload.terminated? }.from(false).to(true).
          and change { role.delete_on }.to(terminate_on).
          and not_change { roles(:mitglied).reload.terminated? }.from(false).
        and not_change { roles(:mitglied).delete_on }
      end
    end

    context 'family_member roles' do
      it 'terminates stammsektion and zusatzsektion for all family members' do
        expect { subject.call }.
          to change { role.reload.terminated? }.from(false).to(true).
          and change { role.delete_on }.to(terminate_on).
          and change { roles(:familienmitglied_zweitsektion).reload.terminated? }.from(false).to(true).
          and change { roles(:familienmitglied_zweitsektion).delete_on }.to(terminate_on).
          and change { roles(:familienmitglied2).reload.terminated? }.from(false).to(true).
          and change { roles(:familienmitglied2).delete_on }.to(terminate_on).
          and change { roles(:familienmitglied2_zweitsektion).reload.terminated? }.from(false).to(true).
          and change { roles(:familienmitglied2_zweitsektion).delete_on }.to(terminate_on).
          and change { roles(:familienmitglied_kind).reload.terminated? }.from(false).to(true).
          and change { roles(:familienmitglied_kind).delete_on }.to(terminate_on).
          and change { roles(:familienmitglied_kind_zweitsektion).reload.terminated? }.from(false).to(true).
          and change { roles(:familienmitglied_kind_zweitsektion).delete_on }.to(terminate_on)
      end

      it 'dont get terminated if invalid' do
        allow(subject).to receive(:valid?).and_return(false)
        expect do
          expect(subject.call).to eq false
        end.
          to not_change { role.reload.terminated? }.from(false).
          and not_change { role.delete_on }.
          and not_change { roles(:familienmitglied2).reload.terminated? }.from(false).
          and not_change { roles(:familienmitglied2).delete_on }.
          and not_change { roles(:familienmitglied_kind).reload.terminated? }.from(false).
          and not_change { roles(:familienmitglied_kind).delete_on }
      end

      context 'abo roles' do
        let(:role) do
          Group::AboMagazin::Abonnent
            .create!(group: groups(:abo_die_alpen), person: person)
        end

        it 'only terminates abo magazin but no other roles' do
          expect { subject.call }.
            to change { role.reload.terminated? }.from(false).to(true).
            and change { role.delete_on }.to(terminate_on).
            and not_change { roles(:familienmitglied2).reload.terminated? }.from(false).
            and not_change { roles(:familienmitglied2).delete_on }.
            and not_change { roles(:familienmitglied_kind).reload.terminated? }.from(false).
            and not_change { roles(:familienmitglied_kind).delete_on }
        end
      end

      context 'zusatzsektion' do
        let(:role) { roles(:familienmitglied2_zweitsektion) }

        it 'terminates zusatzsektion for all family members roles only' do
          expect { subject.call }.
            to change { role.reload.terminated? }.from(false).to(true).
            and change { role.delete_on }.to(terminate_on).
            and change { roles(:familienmitglied_zweitsektion).reload.terminated? }.from(false).to(true).
            and change { roles(:familienmitglied_zweitsektion).delete_on }.to(terminate_on).
            and change { roles(:familienmitglied_kind_zweitsektion).reload.terminated? }.from(false).to(true).
            and change { roles(:familienmitglied_kind_zweitsektion).delete_on }.to(terminate_on).
            and not_change { roles(:familienmitglied).reload.terminated? }.from(false).
            and not_change { roles(:familienmitglied).delete_on }.
            and not_change { roles(:familienmitglied2).reload.terminated? }.from(false).
            and not_change { roles(:familienmitglied2).delete_on }.
            and not_change { roles(:familienmitglied_kind).reload.terminated? }.from(false).
            and not_change { roles(:familienmitglied_kind).delete_on }
        end
      end
    end
  end

  context '#main_person' do
    it 'returns role person' do
      expect(subject.main_person).to eq role.person
    end
  end

  context '#affected_people' do
    context 'for stammsektion role' do
      let(:role) { roles(:familienmitglied) }

      it 'return all other family members' do
        expected_people = role.person.sac_family.family_members - [role.person]
        expect(expected_people).to be_present
        expect(subject.affected_people).to match_array expected_people
      end
    end

    context 'for other role' do
      let(:role) do
        Fabricate.build(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
                        person: people(:familienmitglied),
                        group: groups(:matterhorn_mitglieder))
      end

      it 'returns empty array' do
        expect(subject.affected_people).to eq []
      end
    end
  end
end
