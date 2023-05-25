# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


require 'spec_helper'

describe :self_registration do

  subject { page }

  class Group::SelfRegistrationGroup < Group
    self.layer = true

    class ReadOnly < ::Role
      self.permissions = [:group_read]
    end

    roles ReadOnly
  end

  let(:group) do
    Group::SelfRegistrationGroup.create!(name: 'Self-Registration Group')
  end

  let(:self_registration_role) { group.decorate.allowed_roles_for_self_registration.first }

  before do
    group.self_registration_role_type = self_registration_role
    group.save!

    allow(Settings.groups.self_registration).to receive(:enabled).and_return(true)
  end

  it 'self registers and creates new person' do
    visit group_self_registration_path(group_id: group)

    fill_in 'Vorname', with: 'Max'
    fill_in 'Nachname', with: 'Muster'
    fill_in 'Adresse', with: 'Musterplatz'
    fill_in 'role_new_person_zip_code', with: '8000'
    fill_in 'role_new_person_town', with: 'Zürich'
    fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
    fill_in 'Geburtstag', with: '01.01.1980'

    expect do
      find_all('.btn-toolbar.bottom .btn-group button[type="submit"]').first.click # submit
    end.to change { Person.count }.by(1)
      .and change { ActionMailer::Base.deliveries.count }.by(1)

    is_expected.to have_text('Du hast Dich erfolgreich registriert. Du erhältst in Kürze eine E-Mail mit der Anleitung, wie Du Deinen Account freischalten kannst.')

    person = Person.find_by(email: 'max.muster@hitobito.example.com')
    expect(person).to be_present

    person.confirm # confirm email

    person.password = person.password_confirmation = 'really_b4dPassw0rD'
    person.save!

    fill_in 'Haupt-E-Mail', with: 'max.muster@hitobito.example.com'
    fill_in 'Passwort', with: 'really_b4dPassw0rD'
    
    click_button 'Anmelden'

    expect(person.roles.map(&:type)).to eq([self_registration_role.to_s])
    expect(current_path).to eq("/de#{group_person_path(group_id: group, id: person)}.html")
  end


end
