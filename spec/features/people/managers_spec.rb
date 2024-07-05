require "spec_helper"

describe "people management", :js do
  let(:current_user) { people(:admin) }
  let(:heading) { "Kinder / Verwalter*innen" }
  let(:adult) { create_person(birthday: 25.years.ago) }
  let(:child) { create_person(birthday: 15.years.ago) }

  def create_person(**opts)
    Fabricate(:person, primary_group: groups(:externe_kontakte), **opts).tap do |person|
      create_contact_role(person) # add a role to make the person findable
    end
  end

  def create_contact_role(person)
    Group::ExterneKontakte::Kontakt.create!(person: person, group: groups(:externe_kontakte))
  end

  def within_turbo_frame
    within("turbo-frame#people_managers") do
      yield
    end
  end

  def find_person(name)
    # The dropdown does not reliably open in capybara. Filling in any string first seems to help.
    fill_in "Person suchen...", with: " "
    fill_in "Person suchen...", with: name
    find('ul[role="listbox"] li[role="option"]', text: name).click
  end

  before { sign_in(current_user) }

  it "can assign and remove managed child to adult" do
    visit group_person_path(group_id: adult.primary_group_id, id: adult)

    within_turbo_frame do
      expect(page).to have_css("h2", text: heading)
      click_link("Kind zuweisen")
      find_person child.full_name
      click_on "Speichern"
      expect(page).to have_css("h2", text: "Kinder")
      expect(page).to have_link child.full_name
      expect(page).to have_link "Kind zuweisen"
    end

    refresh
    # check that the managed is also added to the household
    within(".contactable") do
      expect(page).to have_link(child.full_name)
    end

    within_turbo_frame do
      accept_alert("wirklich löschen") do
        click_link "Löschen"
      end
      expect(page).to have_css("h2", text: heading)
      expect(page).not_to have_link "Bottom Member"
    end

    refresh
    # check that the managed is also removed from the household
    within(".contactable") do
      expect(page).to have_no_link(child.full_name)
    end
  end

  it "cannot assign managed adult to adult" do
    create_person(birthday: 25.years.ago)
    visit group_person_path(group_id: adult.primary_group_id, id: adult)

    within_turbo_frame do
      expect(page).to have_css("h2", text: heading)
      expect(page).to have_link("Kind zuweisen")
      expect(page).to have_link(count: 1)
    end
  end

  it "cannot assign manager to child" do
    visit group_person_path(group_id: child.primary_group_id, id: child)

    within_turbo_frame do
      expect(page).to have_css("h2", text: heading)
      expect(page).to have_no_link
    end
  end

  it "cannot assign managed to child" do
    visit group_person_path(group_id: child.primary_group_id, id: child)

    within_turbo_frame do
      expect(page).to have_css("h2", text: heading)
      expect(page).to have_no_link
    end
  end
end
