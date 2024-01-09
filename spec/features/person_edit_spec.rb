# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'person edit page', js: true do
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:familienmitglied) { people(:familienmitglied) }
  let(:geschaeftsstelle) { groups(:geschaeftsstelle) }
  let(:mitglieder) { groups(:bluemlisalp_mitglieder) }
  let(:other) do
    Fabricate(Group::Sektion.sti_name, parent: groups(:root), foundation_year: 2023)
    .children.find_by(type: Group::SektionsMitglieder)
  end


  describe 'managed' do
    context 'with feature gate enabled' do
      before do
        allow(FeatureGate).to receive(:enabled?).with('people.people_managers.self_service_managed_creation').and_return(true)
        allow(FeatureGate).to receive(:enabled?).and_return(true)
      end

      context 'with writing permission on any person' do
        before { sign_in(admin) }

        context 'with role with beitragskategorie einzel' do
          it 'does not find new person managed fields' do
            visit edit_group_person_path(group_id: mitglieder.id, id: mitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              expect(page).to_not have_field('Vorname')
              expect(page).to_not have_field('Nachname')
              expect(page).to_not have_field('Geburtstag')
              expect(page).to have_css('input[type="text"][placeholder="Person suchen..."]')
            end
          end
        end

        context 'with role with beitragskategorie familie' do
          it 'does not find new person managed fields' do
            visit edit_group_person_path(group_id: mitglieder.id, id: familienmitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              expect(page).to_not have_field('Vorname')
              expect(page).to_not have_field('Nachname')
              expect(page).to_not have_field('Geburtstag')
              expect(page).to have_css('input[type="text"][placeholder="Person suchen..."]')
            end
          end
        end
      end

      context 'without writing permission on any person' do
        context 'with role with beitragskategorie einzel' do
          before { mitglied.roles.update_all(delete_on: Time.zone.now.end_of_year) }

          before { sign_in(mitglied) }

          it 'creates new person as managed but assigns no role' do
            visit edit_group_person_path(group_id: mitglieder.id, id: mitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')

            birthday = 11.years.ago
            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              fill_in('Vorname', with: 'Bob')
              fill_in('Nachname', with: 'Builder')
              fill_in('Geburtstag', with: birthday.strftime('%d.%m.%Y'))
            end

            expect do
              within('.bottom') do
                click_button 'Speichern'
              end
            end.to change { Person.count }.by(1)
              .and change { PeopleManager.count }.by(1)

            mitglied.reload
            managed = mitglied.manageds.first
            expect(managed.first_name).to eq('Bob')
            expect(managed.last_name).to eq('Builder')
            expect(managed.birthday).to eq(birthday.to_date)

            expect(managed.roles.size).to eq(0)
          end

          it 'does not create new person as managed if mitglied age is below 22' do
            mitglied.update(birthday: 21.years.ago)

            visit edit_group_person_path(group_id: mitglieder.id, id: mitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')

            birthday = 11.years.ago
            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              fill_in('Vorname', with: 'Bob')
              fill_in('Nachname', with: 'Builder')
              fill_in('Geburtstag', with: birthday.strftime('%d.%m.%Y'))
            end

            expect do
              within('.bottom') do
                click_button 'Speichern'
              end
            end.to_not change { Person.count }

            expect(page).to have_content('muss mindestens 22 Jahre alt sein um Kinder zu erfassen')
          end

          it 'does not create new person as managed if new person age is below 6' do
            visit edit_group_person_path(group_id: mitglieder.id, id: mitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')

            birthday = 5.years.ago
            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              fill_in('Vorname', with: 'Bob')
              fill_in('Nachname', with: 'Builder')
              fill_in('Geburtstag', with: birthday.strftime('%d.%m.%Y'))
            end

            expect do
              within('.bottom') do
                click_button 'Speichern'
              end
            end.to_not change { Person.count }

            expect(page).to have_content('Kinder müssen zwischen 6 und 17 Jahre alt sein')
          end

          it 'does not create new person as managed if new person age is above 17' do
            visit edit_group_person_path(group_id: mitglieder.id, id: mitglied.id)

            find('a[data-association="people_manageds"]').click

            birthday = 18.years.ago
            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              fill_in('Vorname', with: 'Bob')
              fill_in('Nachname', with: 'Builder')
              fill_in('Geburtstag', with: birthday.strftime('%d.%m.%Y'))
            end

            expect do
              within('.bottom') do
                click_button 'Speichern'
              end
            end.to_not change { Person.count }

            expect(page).to have_content('Kinder müssen zwischen 6 und 17 Jahre alt sein')
          end
        end

        context 'with role with beitragskategorie familie' do
          before { familienmitglied.roles.update_all(delete_on: Time.zone.now.end_of_year) }

          before { sign_in(familienmitglied) }

          it 'creates new person as managed and assigns role' do
            visit edit_group_person_path(group_id: mitglieder.id, id: familienmitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')

            birthday = 11.years.ago
            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              fill_in('Vorname', with: 'Bob')
              fill_in('Nachname', with: 'Builder')
              fill_in('Geburtstag', with: birthday.strftime('%d.%m.%Y'))
            end

            expect do
              within('.bottom') do
                click_button 'Speichern'
              end
            end.to change { Person.count }.by(1)
              .and change { PeopleManager.count }.by(1)

            familienmitglied.reload
            managed = familienmitglied.manageds.first
            expect(managed.first_name).to eq('Bob')
            expect(managed.last_name).to eq('Builder')
            expect(managed.birthday).to eq(birthday.to_date)

            expect(managed.roles.size).to eq(2)
            managed_mitglied_role, managed_zusatzmitglied_role = managed.roles

            expect(managed_mitglied_role.type).to eq('Group::SektionsMitglieder::Mitglied')
            expect(managed_mitglied_role.beitragskategorie).to eq('familie')
            expect(managed_mitglied_role.group).to eq(mitglieder)

            expect(managed_zusatzmitglied_role.type).to eq('Group::SektionsMitglieder::MitgliedZusatzsektion')
            expect(managed_zusatzmitglied_role.beitragskategorie).to eq('familie')
            expect(managed_zusatzmitglied_role.group).to eq(groups(:matterhorn_mitglieder))
          end
        end
      end
    end

    context 'with feature gate disabled' do
      before do
        allow(FeatureGate).to receive(:enabled?).with('people.people_managers.self_service_managed_creation').and_return(false)
      end

      context 'with writing permission on any person' do
        context 'with role with beitragskategorie einzel' do
          before { sign_in(admin) }

          it 'does not find new person managed fields' do
            visit edit_group_person_path(group_id: mitglieder.id, id: mitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              expect(page).to_not have_field('Vorname')
              expect(page).to_not have_field('Nachname')
              expect(page).to_not have_field('Geburtstag')
              expect(page).to have_css('input[type="text"][placeholder="Person suchen..."]')
            end
          end
        end

        context 'with role with beitragskategorie familie' do
          before { sign_in(admin) }

          it 'does not find new person managed fields' do
            visit edit_group_person_path(group_id: mitglieder.id, id: familienmitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              expect(page).to_not have_field('Vorname')
              expect(page).to_not have_field('Nachname')
              expect(page).to_not have_field('Geburtstag')
              expect(page).to have_css('input[type="text"][placeholder="Person suchen..."]')
            end
          end
        end
      end

      context 'without writing permission on any person' do
        context 'with role with beitragskategorie einzel' do
          before { mitglied.roles.update_all(delete_on: Time.zone.now.end_of_year) }

          before { sign_in(mitglied) }

          it 'does not find new person managed fields' do
            visit edit_group_person_path(group_id: mitglieder.id, id: mitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              expect(page).to_not have_field('Vorname')
              expect(page).to_not have_field('Nachname')
              expect(page).to_not have_field('Geburtstag')
              expect(page).to have_css('input[type="text"][placeholder="Person suchen..."]')
            end
          end
        end

        context 'with role with beitragskategorie familie' do
          before { familienmitglied.roles.update_all(delete_on: Time.zone.now.end_of_year) }

          before { sign_in(familienmitglied) }

          it 'does not find new person managed fields' do
            visit edit_group_person_path(group_id: mitglieder.id, id: familienmitglied.id)

            find('a[data-association="people_manageds"]').click

            expect(page).to have_css('#people_manageds_fields')
            within('#people_manageds_fields') do
              expect(page).to_not have_field('Vorname')
              expect(page).to_not have_field('Nachname')
              expect(page).to_not have_field('Geburtstag')
              expect(page).to have_css('input[type="text"][placeholder="Person suchen..."]')
            end
          end
        end
      end
    end
  end
end
