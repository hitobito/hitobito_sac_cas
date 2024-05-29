# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe People::SacFamilyMainPersonController, type: :controller do
  let(:adult) { people(:familienmitglied) }
  let(:adult2) { people(:familienmitglied2) }
  let(:child) { people(:familienmitglied_kind) }

  let(:today) { Time.zone.today }
  let(:end_of_year) do
    if today == today.end_of_year
      (today + 1.days).end_of_year
    else
      today.end_of_year
    end
  end

  let!(:household_member_youth) do
    person = Fabricate(:person, household_key: '4242', birthday: today - 19.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:bluemlisalp_mitglieder),
      person: person,
      beitragskategorie: :youth,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  let!(:household_member_adult) do
    person = Fabricate(:person, household_key: '4242', birthday: today - 42.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:bluemlisalp_mitglieder),
      person: person,
      beitragskategorie: :adult,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  let!(:household_other_sektion_member) do
    person = Fabricate(:person, household_key: '4242', birthday: today - 88.years)
    Group::SektionsMitglieder::Mitglied.create!(
      group: groups(:matterhorn_mitglieder),
      person: person,
      beitragskategorie: :adult,
      created_at: today.beginning_of_year,
      delete_on: end_of_year
    )
    person
  end

  let(:person) do
    person = Fabricate(:person, birthday: Time.zone.today - 42.years,  household_key: 'household-99')
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
              person: person,
              beitragskategorie: :adult,
              group: groups(:bluemlisalp_mitglieder)
              )
    person
  end

  let(:other_person) do
    other_person = Fabricate(:person, birthday: Time.zone.today - 42.years, household_key: 'household-99' )
    Fabricate(Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
              person: other_person,
              beitragskategorie: :adult,
              group: groups(:bluemlisalp_mitglieder),
              )
      other_person
  end

  let(:mitgliederverwaltung_sektion) do
    Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
              group: groups(:bluemlisalp_funktionaere)).person
  end

describe 'PUT #update' do
  before { sign_in mitgliederverwaltung_sektion }

  context 'when the person is already the main family person' do
    before { person.update!(sac_family_main_person: true) }

    it 'redirects to the person show view' do
      put :update, params: { id: person.id }
      expect(response).to redirect_to(person)
    end
  end

  context 'when the person is not associated with any household' do
    before { person.update!(household_key: nil) }

    it 'returns a 422 status with an error message' do
      put :update, params: { id: person.id }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to eq('Person is not associated with any household')
    end
  end

  context 'when the update is successful' do
    it 'sets the sac_family_main_person to true for adult1 and false for others' do
      put :update, params: { id: adult.id }
      expect(response).to redirect_to(adult)

      adult.reload
      adult2.reload
      child.reload
      expect(person.sac_family_main_person).to be_truthy
      expect(adult2.sac_family_main_person).to be_falsey
      expect(child.sac_family_main_person).to be_falsey
    end

    it 'sets the sac_family_main_person to true for adult2 and false for others' do
      expect(adult2.sac_family_main_person).to be_falsey

      put :update, params: { id: adult2.id }
      expect(response).to redirect_to(adult2)

      adult.reload
      adult2.reload
      child.reload
      expect(person.sac_family_main_person).to be_falsey
      expect(adult2.sac_family_main_person).to be_truthy
      expect(child.sac_family_main_person).to be_falsey
    end
  end

  context 'when the user does not have permissions' do
    before { sign_in person }

    it 'returns a 403 status with an error message' do
      put :update, params: { id: person.id } rescue
      expect(response).to have_http_status(:forbidden)
    end
  end
end

end
