#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "people/_show_right_z_sac_cas.html.haml" do
  include FormatHelper

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow(view).to receive_messages(current_user: person)
    allow(view).to receive_messages(entry: PersonDecorator.decorate(person))
    allow(controller).to receive_messages(current_user: Person.new)
    allow(view).to receive(:can?).with(:update, person).and_return true
  end

  context "member" do
    let(:person) { Person.with_membership_years.find(people(:mitglied).id) }

    it "renders download button for active membership" do
      expect(dom).to have_link(nil, href: membership_path(person, format: :pdf))
    end

    it "renders membership info for active membership" do
      expect(dom).to have_css "section.sac-membership"
      expect(dom).to have_css "section.sac-membership .qr-code-wrapper"
    end

    it "renders membership info for past membership" do
      person.roles.update_all(end_on: 1.day.ago)

      expect(dom).to have_css "section.sac-membership"
      expect(dom).to have_css "section.sac-membership .qr-code-wrapper"
    end

    it "renders membership info for future membership" do
      person.roles.destroy_all
      Group::SektionsMitglieder::Mitglied.create!(
        person:,
        group: groups(:bluemlisalp_mitglieder),
        start_on: 1.month.from_now,
        end_on: 1.year.from_now
      )

      expect(dom).to have_css "section.sac-membership"
      expect(dom).to have_css "section.sac-membership .qr-code-wrapper"
    end
  end

  context "other" do
    let(:person) { people(:admin) }

    it "hides membership info" do
      expect(dom).not_to have_css "section.sac-membership"
    end

    it "does not render download button for inactive membership" do
      expect(dom).not_to have_link(nil, href: membership_path(person, format: :pdf))
    end
  end
end
