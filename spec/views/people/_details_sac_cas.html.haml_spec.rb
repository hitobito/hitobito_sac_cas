#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "people/_details_sac_cas.html.haml" do
  include FormatHelper

  let(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    allow(view).to receive_messages(current_user: person)
    allow(view).to receive_messages(entry: PersonDecorator.decorate(person))
    allow(controller).to receive_messages(current_user: Person.new)
  end

  context "family member" do
    let(:person) { people(:familienmitglied2) }

    it "renders family_id" do
      expect(person.family_id).to be_present # check assumption
      label_node = dom.find("dl dt", text: "Familien ID")
      value_node = label_node.find("+dd")
      expect(value_node.text).to eq person.family_id
    end

    describe "sac_family_main_person" do
      let(:label_node) { dom.find("dl dt", text: "Rechnungen an (Familie)") }

      subject(:value_node) { label_node.find("+dd") }

      it "renders unknown if family has no main person" do
        # clear family_main_person for all family members
        Person.where(household_key: person.household_key).update_all(sac_family_main_person: false)

        expect(value_node.text).to eq I18n.t("global.unknown")
      end

      it "renders true if person is main person" do
        # clear family_main_person for all family members and set it for this person
        Person.where(household_key: person.household_key).update_all(sac_family_main_person: false)
        person.update!(sac_family_main_person: true)

        expect(value_node.text).to eq I18n.t("global.yes")
      end

      it "renders main person name if person is not main person" do
        expect(person.household.main_person).to eq people(:familienmitglied) # check assumption

        expect(value_node).to have_text(person.household.main_person.to_s)
      end

      it "renders link to main person if person is not main person" do
        expect(person.household.main_person).to eq people(:familienmitglied) # check assumption
        expect(view).to receive(:can?).with(:show, person.household.main_person).and_return(true)

        expect(value_node).to have_link(person.household.main_person.to_s, href: person_path(person.household.main_person))
      end
    end
  end

  context "member" do
    let(:person) { Person.with_membership_years.find(people(:mitglied).id) }

    it "renders membership info for active membership" do
      expect(dom).to have_css "dl dt", text: "Mitgliederausweis & Rechnungsstellung"
      expect(dom).to have_css "dl dt", text: "E-Mail bestätigt"
      expect(dom).to have_css "dl dt", text: "Anzahl Mitglieder-Jahre"
      expect(dom).to have_css "dl dt", text: "Mitglied-Nr"
    end

    it "renders membership info for past membership" do
      person.roles.update_all(end_on: 1.day.ago)
      expect(dom).to have_css "dl dt", text: "Anzahl Mitglieder-Jahre"
      expect(dom).to have_css "dl dt", text: "Mitglied-Nr"
    end

    it "renders membership info for future membership" do
      person.roles.destroy_all
      Group::SektionsMitglieder::Mitglied.create!(
        person:,
        group: groups(:bluemlisalp_mitglieder),
        start_on: 1.month.from_now,
        end_on: 2.months.from_now
      )
      expect(dom).to have_css "dl dt", text: "Anzahl Mitglieder-Jahre"
      expect(dom).to have_css "dl dt", text: "Mitglied-Nr"
    end
  end

  context "other" do
    let(:person) { people(:admin) }

    it "hides membership info" do
      expect(dom).not_to have_css "dl dt", text: "Anzahl Mitglieder-Jahre"
      expect(dom).not_to have_css "dl dt", text: "Mitglied-Nr"
    end

    it "hides family info" do
      expect(dom).not_to have_css "dl dt", text: I18n.t("activerecord.attributes.person.family_id")
      expect(dom).not_to have_css "dl dt", text: I18n.t("activerecord.attributes.person.sac_family_main_person")
    end
  end
end
