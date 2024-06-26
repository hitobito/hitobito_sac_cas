# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Memberships::LeaveZusatzsektion do
  def create_role(key, role, owner: person, **attrs)
    group = key.is_a?(Group) ? key : groups(key)
    role_type = group.class.const_get(role)
    Fabricate(role_type.sti_name, group: group, person: owner, **attrs)
  end

  describe 'initialization exceptions' do
    it 'raises if role type is invalid' do
      expect do
        described_class.new(Role.new, :termination_date)
      end.to raise_error('wrong type')
    end

    it 'raises if role is family and person is not main person' do
      expect do
        role = Group::SektionsMitglieder::MitgliedZusatzsektion.new(
          beitragskategorie: 'family',
          person: Person.new
        )
        described_class.new(role, :termination_date)
      end.to raise_error('not main family person')
    end
  end

  let(:now) { Time.zone.local(2024, 6, 19, 15, 33) }
  let(:terminate_on) { now.yesterday.to_date }
  subject(:leave) { described_class.new(role, terminate_on) }
  before { travel_to(now) }

  describe 'validations' do
    let(:person) { Fabricate(:person) }
    let!(:mitglied) { create_role(:matterhorn_mitglieder, 'Mitglied', owner: person) }
    let!(:role) { create_role(:bluemlisalp_mitglieder, 'MitgliedZusatzsektion', owner: person) }

    it 'is valid' do
      expect(leave).to be_valid
    end

    describe 'validates date' do
      def leave_on(date) = described_class.new(role, date)

      it 'is valid on yesterday and at the end of current year' do
        expect(leave_on(now.yesterday.to_date)).to be_valid
        expect(leave_on(now.end_of_year.to_date)).to be_valid
        expect(leave_on(now)).not_to be_valid
        expect(leave_on(now.next_year.beginning_of_year)).not_to be_valid
        expect(leave_on(now.next_year.beginning_of_year.to_date + 1.day)).not_to be_valid
      end
    end
  end

  describe 'saving' do
    let(:person) { Fabricate(:person) }

    context 'single person' do
      let!(:mitglied) { create_role(:matterhorn_mitglieder, 'Mitglied', owner: person) }
      let!(:role) { create_role(:bluemlisalp_mitglieder, 'MitgliedZusatzsektion', owner: person) }

      it 'deletes existing role' do
        expect do
          expect(leave.save).to eq true
        end.to change { person.roles.count }.by(-1)
        expect { Role.find(role.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes existing role when already schedule for deletion' do
        Roles::Termination.terminate([role], 3.days.from_now.to_date)
        role.save!
        expect do
          expect(leave.save).to eq true
        end.to change { person.roles.count }.by(-1)
        expect { Role.find(role.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'with terminate_on at the end of year' do
        let(:terminate_on) { now.end_of_year.to_date }

        it 'schedules role for deletion' do
          expect do
            expect(leave.save).to eq true
          end.not_to(change { person.roles.count })
          expect(role.reload).to be_terminated
          expect(role.delete_on).to eq Date.new(2024, 12, 31)
        end

        it 'does not reset delete_on to a later date' do
          Roles::Termination.terminate([role], 3.days.from_now.to_date)
          role.save!
          expect do
            expect(leave.save).to eq true
          end.not_to(change { person.roles.count })
          expect(role.reload).to be_terminated
          expect(role.delete_on).to eq 3.days.from_now.to_date
        end
      end
    end

    context 'family person' do
      let(:other) { Fabricate(:person) }
      let(:matterhorn_mitglieder) { groups(:matterhorn_mitglieder) }

      subject(:leave) { described_class.new(@matterhorn_zusatz, terminate_on) }

      def create_sac_family(person, *others)
        person.update!(sac_family_main_person: true)
        household = Household.new(person)
        others.each { |member| household.add(member) }
        household.save!
        person.reload
        others.each(&:reload)
      end

      before do
        person.update!(sac_family_main_person: true)
        @bluemlisalp_mitglied = create_role(:bluemlisalp_mitglieder, 'Mitglied')
        @bluemlisalp_mitglied_other = create_role(:bluemlisalp_mitglieder, 'Mitglied', owner: other.reload)
        create_sac_family(person, other)
        Role.where(id: [@bluemlisalp_mitglied.id, @bluemlisalp_mitglied_other.id]).update_all(beitragskategorie: :family)

        @matterhorn_zusatz = create_role(
          :matterhorn_mitglieder, 'MitgliedZusatzsektion',
          owner: person
        )
        @matterhorn_zusatz_other = create_role(
          :matterhorn_mitglieder, 'MitgliedZusatzsektion',
          owner: other
        )
      end

      it 'deletes existing roles' do
        expect do
          expect(leave.save).to eq true
        end.to change { Role.count }.by(-2)
        expect { Role.find(@matterhorn_zusatz.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect do
          Role.find(@matterhorn_zusatz_other.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'with terminate_on at the end of year' do
        let(:terminate_on) { now.end_of_year.to_date }

        it 'schedules role for deletion' do
          expect do
            expect(leave.save).to eq true
          end.not_to(change { person.roles.count })
          expect(@matterhorn_zusatz.reload).to be_terminated
          expect(@matterhorn_zusatz_other.delete_on).to eq Date.new(2024, 12, 31)
        end
      end
    end
  end
end
