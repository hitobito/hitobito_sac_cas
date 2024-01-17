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


  context '#affected_roles' do
    around do |example|
      Group::SektionsFunktionaere::Administration.terminatable = true
      example.run
      Group::SektionsFunktionaere::Administration.terminatable = false
    end

    context 'for a mitglied role' do
      let(:role) { roles(:mitglied) }

      it 'returns the role and all other mitglied roles of the person' do
        expect(subject.affected_roles).to eq [role, roles(:mitglied_zweitsektion)]
      end
    end

    context 'for a non-mitglied role' do
      let(:role) do
        Group::SektionsFunktionaere::Praesidium.create!(
          person: person,
          group: groups(:bluemlisalp_funktionaere)
        )
      end

      it 'for a non-mitglied role returns only the role' do
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
      let(:role) { roles(:familienmitglied_zweitsektion) }

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

    context 'family_member roles' do
      it 'terminates family member roles' do
        expect(subject.family_member_roles).to eq [roles(:familienmitglied2),
                                                   roles(:familienmitglied_kind)]

        expect { subject.call }.
          to change { role.reload.terminated? }.from(false).to(true).
          and change { role.delete_on }.to(terminate_on).
          and change { roles(:familienmitglied2).reload.terminated? }.from(false).to(true).
          and change { roles(:familienmitglied2).delete_on }.to(terminate_on).
          and change { roles(:familienmitglied_kind).reload.terminated? }.from(false).to(true).
          and change { roles(:familienmitglied_kind).delete_on }.to(terminate_on)
      end

      it 'dont get terminated if invalid' do
        allow(subject).to receive(:valid?).and_return(false)
        expect do
          expect(subject.call).to eq false
        end.
          to not_change { role.reload.terminated? }.from(false).
          and not_change { role.delete_on }.
          and not_change { roles(:familienmitglied2).reload.terminated? }.from(false).
          and not_change { roles(:mitglied_zweitsektion).delete_on }.
          and not_change { roles(:familienmitglied_kind).reload.terminated? }.from(false).
          and not_change { roles(:familienmitglied_kind).delete_on }
      end
    end
  end
end
