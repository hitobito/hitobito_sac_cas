# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe 'neuanmeldungen approval', js: true do

  let(:neuanmeldungen) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:neuanmeldungen_approved) { groups(:bluemlisalp_neuanmeldungen_nv) }

  let!(:role1) { create_neuanmeldung }
  let!(:role2) { create_neuanmeldung }
  let!(:role3) { create_neuanmeldung }

  before { sign_in(people(:admin)) }

  context 'multiselect actions' do
    it 'has the specified buttons' do
      visit group_people_path(group_id: neuanmeldungen.id)
      check_person(role1)

      within('.multiselect') do
        expect(page).to have_no_link('Rollen')
        expect(page).to have_no_link('Zu Veranstaltung hinzufügen')
        expect(page).to have_no_link('Zu Abo hinzufügen')

        expect(page).to have_link('Tags')
        expect(page).to have_link('Übernehmen')
        expect(page).to have_link('Ablehnen')
      end
    end

    it 'has no buttons when no people are selected' do
      visit group_people_path(group_id: neuanmeldungen.id)

      expect(page).to have_no_selector('.multiselect')
      expect(page).to have_no_link('Tags')
      expect(page).to have_no_link('Übernehmen')
      expect(page).to have_no_link('Ablehnen')
    end
  end

  context 'approve' do
    it 'approves a single person' do
      visit(group_people_path(group_id: neuanmeldungen_approved.id))
      expect(page).to have_text('Keine Einträge gefunden.')

      visit(group_people_path(group_id: neuanmeldungen.id))
      check_person(role1)
      click_link('Übernehmen')

      expect(page).to have_selector('#neuanmeldungen-handler.modal')
      within('#neuanmeldungen-handler.modal') do
        expect(page).to have_selector('.modal-title', text: 'Anmeldung übernehmen')
        expect(page).to have_selector('.modal-body',
                                      text: 'Bitte bestätigen Sie die Übernahme der ausgewählten Anmeldung.')
        click_button('1 Übernehmen')
      end

      expect(page).to have_no_selector('#neuanmeldungen-handler.modal')
      expect(page).to have_selector('#flash .alert-success', text: 'Anmeldung wurde übernommen')
      expect(page).to have_no_selector(person_selector(role1))
      expect(page).to have_selector(person_selector(role2))
      expect(page).to have_selector(person_selector(role3))

      visit(group_people_path(group_id: neuanmeldungen_approved.id))
      expect(page).to have_selector(person_selector(role1))
    end

    it 'approves multiple people' do
      visit(group_people_path(group_id: neuanmeldungen.id))
      check_person(role1)
      check_person(role2)
      click_link('Übernehmen')

      expect(page).to have_selector('#neuanmeldungen-handler.modal')
      within('#neuanmeldungen-handler.modal') do
        expect(page).to have_selector('.modal-title', text: 'Anmeldungen übernehmen')
        expect(page).to have_selector('.modal-body',
                                      text: 'Bitte bestätigen Sie die Übernahme der ausgewählten Anmeldungen.')
        click_button('2 Übernehmen')
      end

      expect(page).to have_no_selector('#neuanmeldungen-handler.modal')
      expect(page).to have_selector('#flash .alert-success', text: 'Anmeldungen wurden übernommen')
      expect(page).to have_no_selector(person_selector(role1))
      expect(page).to have_no_selector(person_selector(role2))
      expect(page).to have_selector(person_selector(role3))

      visit(group_people_path(group_id: neuanmeldungen_approved.id))
      expect(page).to have_selector(person_selector(role1))
      expect(page).to have_selector(person_selector(role2))
    end
  end

  context 'reject' do
    it 'rejects a single person' do
      visit(group_people_path(group_id: neuanmeldungen.id))
      check_person(role1)
      click_link('Ablehnen')

      expect(page).to have_selector('#neuanmeldungen-handler.modal')
      within('#neuanmeldungen-handler.modal') do
        expect(page).to have_selector('.modal-title', text: 'Anmeldung ablehnen')
        expect(page).to have_selector('.modal-body',
                                      text: 'Bitte bestätigen Sie die Ablehnung der ausgewählten Anmeldung.')
        click_button('1 Ablehnen')
      end

      expect(page).to have_no_selector('#neuanmeldungen-handler.modal')
      expect(page).to have_selector('#flash .alert-success', text: 'Anmeldung wurde abgelehnt')
      expect(page).to have_no_selector(person_selector(role1))
      expect(page).to have_selector(person_selector(role2))
      expect(page).to have_selector(person_selector(role3))

      visit(group_people_path(group_id: neuanmeldungen_approved.id))
      expect(page).to have_text('Keine Einträge gefunden.')
      expect{ role1.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'rejects multiple people' do
      visit(group_people_path(group_id: neuanmeldungen.id))
      check_person(role1)
      check_person(role2)
      click_link('Ablehnen')

      expect(page).to have_selector('#neuanmeldungen-handler.modal')
      within('#neuanmeldungen-handler.modal') do
        expect(page).to have_selector('.modal-title', text: 'Anmeldungen ablehnen')
        expect(page).to have_selector('.modal-body',
                                      text: 'Bitte bestätigen Sie die Ablehnung der ausgewählten Anmeldungen.')
        click_button('2 Ablehnen')
      end

      expect(page).to have_no_selector('#neuanmeldungen-handler.modal')
      expect(page).to have_selector('#flash .alert-success', text: 'Anmeldungen wurden abgelehnt')
      expect(page).to have_no_selector(person_selector(role1))
      expect(page).to have_no_selector(person_selector(role2))
      expect(page).to have_selector(person_selector(role3))

      visit(group_people_path(group_id: neuanmeldungen_approved.id))
      expect(page).to have_text('Keine Einträge gefunden.')

      expect{ role1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect{ role2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  private

  def create_neuanmeldung
    Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.name.to_sym,
              group: neuanmeldungen,
              beitragskategorie: :adult,
              person: Fabricate(:person, birthday: 20.years.ago))
  end

  def person_selector(role)
    "tr#person_#{role.person.id} input[name='ids[]']"
  end

  def check_person(role)
    page.find(person_selector(role)).click
  end
end
