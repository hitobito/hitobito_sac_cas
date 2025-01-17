# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe "people list page", :js do
  let(:person) { people(:admin) }
  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:neuanmeldungen) { groups(:bluemlisalp_neuanmeldungen_sektion) }

  before { sign_in(person) }

  it "allows showing the membership_years column" do
    visit group_people_path(group_id: group.id)
    expect(page).to have_no_css('td[data-attribute-name="membership_years"]')
    click_link("Spalten")
    check("Anzahl Mitglieder-Jahre")
    click_link("Spalten")
    expect(page).to have_css('td[data-attribute-name="membership_years"]', count: 4)
  end

  it "allows showing beitragskategorie column" do
    visit group_people_path(group_id: group.id)
    expect(page).to have_no_css('td[data-attribute-name="beitragskategorie"]')
    click_link("Spalten")
    check("Beitragskategorie")
    click_link("Spalten")
    expect(page).to have_css('td[data-attribute-name="beitragskategorie"]', text: "Einzel", count: 1)
    expect(page).to have_css('td[data-attribute-name="beitragskategorie"]', text: "Familie", count: 3)
  end

  it "allows showing login column" do
    # make sure we have a person with and a person without legacy password
    people(:mitglied).update(wso2_legacy_password_hash: "hash", wso2_legacy_password_salt: "salt")
    expect(people(:familienmitglied).wso2_legacy_password_hash).to be_nil

    visit group_people_path(group_id: group.id)

    expect(page).to have_no_css('td[data-attribute-name="login_status"]')
    click_link("Spalten")
    check("Login")
    click_link("Spalten")
    expect(page).to have_css('td[data-attribute-name="login_status"]', count: 4)
  end

  it "shows certain columns only for neuanmeldungen" do
    Fabricate(Group::SektionsNeuanmeldungenSektion::Neuanmeldung.sti_name, group: neuanmeldungen)
    visit group_people_path(group_id: neuanmeldungen.id)
    click_link("Spalten")

    expect(page).to have_unchecked_field("Antrag für")
    check("Antrag für")
    click_link("Spalten")
    expect(page).to have_css('td[data-attribute-name="antrag_fuer"]', count: 1)

    visit group_people_path(group_id: group.id)
    expect(page).not_to have_css('td[data-attribute-name="antrag_fuer"]')
    click_link("Spalten")
    expect(page).not_to have_checked_field("Antrag für")

    visit group_people_path(group_id: neuanmeldungen.id)
    expect(page).to have_css('td[data-attribute-name="antrag_fuer"]', count: 1)
    click_link("Spalten")
    expect(page).to have_checked_field("Antrag für")
  end

  it "allows showing the sac remarks column" do
    person.roles.destroy_all
    person.roles.create!(
      group: groups(:matterhorn_funktionaere),
      type: Group::SektionsFunktionaere::Administration.sti_name
    )

    visit group_people_path(group_id: person.groups.first.id)
    click_link("Spalten")

    within(".dropdown-menu") do
      expect(page).not_to have_text("Bemerkungen Geschäftsstelle")
      expect(page).to have_text("Bemerkungen Sektion 1")
    end
  end

  it "allows showing the data_quality column" do
    group.people.first.update! data_quality: "info"
    group.people.second.update! data_quality: "warning"
    group.people.third.update! data_quality: "error"

    visit group_people_path(group_id: group.id)
    click_link("Spalten")
    check("Datenqualität")

    expect(page).to have_css("td[data-attribute-name=data_quality] .fas.fa-check-circle")
    expect(page).to have_css("td[data-attribute-name=data_quality] .fas.fa-info-circle")
    expect(page).to have_css("td[data-attribute-name=data_quality] .fas.fa-exclamation-triangle")
    expect(page).to have_css("td[data-attribute-name=data_quality] .fas.fa-times-circle")
  end
end
