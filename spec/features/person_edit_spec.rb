# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe 'person edit page', :js do
  before do
    sign_in(people(:admin))
    people(:familienmitglied2).destroy!
    Role.where.not(delete_on: nil).
      update_all(terminated: true, delete_on: Date.current.end_of_year)
  end

  let(:family_adult) { people(:familienmitglied) }
  let(:family_child) { people(:familienmitglied_kind) }
  let(:non_family_adult) { people(:abonnent) }

  def add_to_household(person, other_person)
    visit edit_group_person_path(group_id: person.primary_group_id, id: person.id)
    check 'Wohnt im Haushalt mit'

    # The dropdown does not reliably open in capybara. Filling in any string first seems to help.
    fill_in 'household_query', with: ' '
    fill_in 'household_query', with: other_person.first_name
    find('.household_query_container ul[role="listbox"] li[role="option"]', text: other_person.first_name).click
    expect(page).to have_selector('.household_key_people a', text: other_person.first_name)

    within('.bottom') { click_on 'Speichern' }
    expect(page).to have_selector('#flash .alert-success', text: 'erfolgreich aktualisiert')
    expect(person.reload.household_key).to be_present
  end

  def remove_from_household(person)
    visit edit_group_person_path(group_id: person.primary_group_id, id: person.id)
    uncheck 'Wohnt im Haushalt mit'
    within('.bottom') { click_on 'Speichern' }
    expect(page).to have_selector('#flash .alert-success', text: 'erfolgreich aktualisiert')
    expect(person.reload.household_key).to be_blank
  end

  context 'household' do
    around { |example| Capybara.using_wait_time(10) { example.run } }

    context 'family memberships' do
      it 'adding non family person to family household adds membership' do
        add_to_household(family_adult, non_family_adult)

        click_on non_family_adult.full_name
        expect(page).to have_selector('.content-header h1', text: non_family_adult.full_name)
        within('section.roles') do
          expect(page).to have_selector('tr', text: "SAC Blüemlisalp / Mitglieder\nMitglied (Stammsektion)")
          expect(page).to have_selector('tr', text: "SAC Matterhorn / Mitglieder\nMitglied (Zusatzsektion)")
        end
      end

      it 'adding family person to non family household adds membership' do
        add_to_household(non_family_adult, family_adult)

        within('section.roles') do
          expect(page).to have_selector('tr', text: "SAC Blüemlisalp / Mitglieder\nMitglied (Stammsektion)")
          expect(page).to have_selector('tr', text: "SAC Matterhorn / Mitglieder\nMitglied (Zusatzsektion)")
        end
      end

      it 'adding family person to non household person adds membership' do
        add_to_household(non_family_adult, family_adult)

        expect(page).to have_selector('.content-header h1', text: non_family_adult.full_name)
        within('section.roles') do
          expect(page).to have_selector('tr', text: "SAC Blüemlisalp / Mitglieder\nMitglied (Stammsektion)")
          expect(page).to have_selector('tr', text: "SAC Matterhorn / Mitglieder\nMitglied (Zusatzsektion)")
        end
      end

      it 'removing person keeps membership' do
        Person::Household.new(non_family_adult, Ability.new(people(:admin)), family_adult).
          tap { |h| h.assign; h.persist! }
        expect(non_family_adult.reload.household_key).to eq family_adult.household_key
        expect(Group::SektionsMitglieder::Mitglied.where(person_id: non_family_adult.id)).to be_exist

        remove_from_household(non_family_adult)

        within('section.roles') do
          expect(page).to have_selector('tr', text: "SAC Blüemlisalp / Mitglieder\nMitglied (Stammsektion)")
          expect(page).to have_selector('tr', text: "SAC Matterhorn / Mitglieder\nMitglied (Zusatzsektion)")
        end
      end
    end

    context 'people_manager' do
      it 'adding minor person to adult adds people_manager' do
        family_adult.update!(birthday: 25.years.ago)
        non_family_adult.update!(birthday: 10.years.ago)
        add_to_household(family_adult, non_family_adult)

        within('section turbo-frame#people_managers') do
          expect(page).to have_selector('tr', text: non_family_adult.full_name)
        end
        expect(family_adult.reload.manageds).to include(non_family_adult)
      end

      it 'adding adult person to minor adds people_manager' do
        add_to_household(family_child, non_family_adult)

        within('section turbo-frame#people_managers') do
          expect(page).to have_selector('tr', text: non_family_adult.full_name)
        end
        expect(family_child.reload.managers).to include(non_family_adult)
      end

      it 'adding adult person to adult does not add people_manager' do
        non_family_adult.update!(birthday: 25.years.ago)
        add_to_household(family_adult, non_family_adult)

        within('section turbo-frame#people_managers') do
          expect(page).to have_no_selector('tr', text: non_family_adult.full_name)
        end
        expect(family_adult.reload.managers).not_to include(non_family_adult)
        expect(family_adult.manageds).not_to include(non_family_adult)
      end

      it 'adding minor person to minor does not add people_manager' do
        family_adult.update!(birthday: 10.years.ago)
        non_family_adult.update!(birthday: 10.years.ago)
        add_to_household(family_adult, non_family_adult)

        within('section turbo-frame#people_managers') do
          expect(page).to have_no_selector('tr', text: non_family_adult.full_name)
        end
        expect(family_adult.reload.managers).not_to include(non_family_adult)
        expect(family_adult.manageds).not_to include(non_family_adult)
      end

      it 'removing person removes people_manager' do
        expect(family_adult.manageds).to be_present
        remove_from_household(family_adult)

        within('section turbo-frame#people_managers') do
          expect(page).to have_no_selector('tr')
        end
        expect(family_adult.manageds).to be_empty
      end
    end
  end
end
