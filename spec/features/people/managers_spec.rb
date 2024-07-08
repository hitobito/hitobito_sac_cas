require "spec_helper"

describe "people management", :js do
  let(:current_user) { people(:admin) }
  let(:heading) { "Kinder / Verwalter*innen" }
  let(:person) { people(:familienmitglied) }

  it "has no managers aside" do
    visit group_person_path(group_id: person.primary_group_id, id: person.id)
    expect(page).to have_no_selector("turbo-frame#people_managers")
    expect(page).to have_no_content(heading)
  end
end
