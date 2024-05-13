# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe PeopleController do

  render_views

  let(:body) { Capybara::Node::Simple.new(response.body) }
  let(:admin) { people(:admin) }

  let(:people_table) { body.all('#main table tbody tr') }
  let(:pagination_info) { body.find('.pagination-info').text.strip }
  let(:members_filter) { body.find('.toolbar-pills > ul > li:nth-child(1)') }
  let(:custom_filter) { body.find('.toolbar-pills > ul > li.dropdown') }

  before { sign_in(admin) }

  context 'GET#index' do
    it 'accepts filter params and lists neuanmeldungen' do
      person1 = Fabricate(:person, birthday: Time.zone.today - 42.years)
      Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.to_s,
                group: groups(:bluemlisalp_neuanmeldungen_nv),
                person: person1)
      person2 = Fabricate(:person, birthday: Time.zone.today - 42.years)
      Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.to_s,
                group: groups(:bluemlisalp_neuanmeldungen_sektion),
                person: person2)
      roles = { role_type_ids: Group::SektionsNeuanmeldungenNv::Neuanmeldung.id }
      get :index, params: { group_id: groups(:root).id, filters: { role: roles }, range: 'deep' }

      expect(members_filter.text).to eq 'Neuanmeldungen (1)'
      expect(members_filter[:class]).not_to eq 'active'

      expect(pagination_info).to eq '1 Person angezeigt.'
      expect(people_table).to have(1).item

    end

    context 'with format=csv and param recipients=true' do
      it 'calls ... with ...' do
        expect do
          get :index, params: {
            format: :csv,
            group_id: groups(:bluemlisalp_mitglieder),
            recipients: true
          }
          expect(response).to be_redirect
        end.to change { Delayed::Job.count }.by(1)

        job = Delayed::Job.last.payload_object
        expect(job).to be_a(Export::PeopleExportJob)

        expect(Export::Tabular::People::SacRecipients).
          to receive(:export)
        job.perform
      end
    end
  end

  context 'GET#show' do
    context 'household_key' do
      def make_person(beitragskategorie, role_class: Group::SektionsMitglieder::Mitglied,
                      group: groups(:bluemlisalp_mitglieder))
        Fabricate(
          :person,
          birthday: Time.zone.today - 33.years,
          household_key: 'household-42',
          sac_family_main_person: true
        ).tap do |person|
          Fabricate(role_class.to_s,
                    group: group,
                    person: person,
                    beitragskategorie: beitragskategorie)
        end
      end

      def expect_household_key(person, visible:)
        matcher = visible ? :have_selector : :have_no_selector

        get :show, params: { id: person.id, group_id: groups(:root).id }

        expect(body).to send(matcher, 'dt', text: 'Familien ID')
        expect(body).to send(matcher, 'dd', text: person.household_key)
      end

      it 'is shown for person with any role having beitragskategorie=familie' do
        person = make_person(:familie)
        expect_household_key(person, visible: true)
      end

      [:einzel, :jugend].each do |beitragskategorie|
        it "is not shown for person with any role having beitragskategorie=#{beitragskategorie}" do
          person = make_person(beitragskategorie)
          expect_household_key(person, visible: false)
        end
      end

      it 'is not shown for person with non-mitglied role' do
        person = make_person(nil, role_class: Group::Geschaeftsstelle::Admin,
                                  group: groups(:geschaeftsstelle))
        expect_household_key(person, visible: false)
      end

    end
  end

  context 'GET#edit' do
    let(:mitglied) { people(:mitglied) }
    let(:admin) { people(:admin) }
    let(:mitgliederverwalter) do
      Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
                group: groups(:bluemlisalp_funktionaere)).person
    end
    let(:sektion) { groups(:bluemlisalp_mitglieder) }

    let(:dom) { Capybara::Node::Simple.new(response.body) }

    it 'should disable birthdate field for member' do
      sign_in(mitglied)
      get :edit, params: { id: mitglied.id, group_id: sektion.id }

      expect(dom).to have_css('#person_birthday[readonly]')
    end

    it 'should not disable birthdate field for admin' do
      sign_in(admin)

      get :edit, params: { id: mitglied.id, group_id: sektion.id }
      expect(dom).to have_css('#person_birthday')
      expect(dom).to have_no_css('#person_birthday[readonly]')
    end

    it 'should not disable birthdate field for mitgliederdienst' do
      sign_in(mitgliederverwalter)

      get :edit, params: { id: mitglied.id, group_id: sektion.id }
      expect(dom).to have_no_css('#person_birthday[readonly]')
    end
  end

  context 'PATCH#update' do
    let(:mitglied) { people(:mitglied) }
    let(:admin) { people(:admin) }
    let(:mitgliederverwalter) do
      Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
                group: groups(:bluemlisalp_funktionaere)).person
    end

    let(:sektion) { groups(:bluemlisalp_mitglieder) }

    let(:new_date) { new_date = Date.new(2023,1,1) }

    it 'should not be possible for mitglied to update their birthdate' do
      sign_in(mitglied)
      patch :update, params: { id: mitglied.id, group_id: sektion.id, person: { first_name: "Andi", birthday:  new_date  } }
      expect(mitglied.reload.first_name).to eq 'Andi'
      expect(mitglied.reload.birthday).not_to eq(new_date)
    end

    it 'should be possible for admin to update any persons birthdate' do
      sign_in(admin)
      patch :update, params: { id: mitglied.id, group_id: sektion.id, person: { first_name: "Andi", birthday:  new_date  } }
      expect(mitglied.reload.first_name).to eq 'Andi'
      expect(mitglied.reload.birthday).to eq(new_date)
    end

    it 'should possible for mitgliederverwalter to update person in sektion' do
      sign_in(mitgliederverwalter)
      patch :update, params: { id: mitglied.id, group_id: sektion.id, person: { first_name: "Andi", birthday:  new_date  } }
      expect(mitglied.reload.first_name).to eq 'Andi'
      expect(mitglied.reload.birthday).to eq(new_date)
    end
  end
end
