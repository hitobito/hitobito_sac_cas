# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::Event::Participation::MailDispatch do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:user) { people(:admin) }
  let(:course) { events(:top_course) }
  let(:group) { groups(:root) }
  let(:participation) do
    Event::Participation.create!(event: course, person: people(:abonnent))
  end
  let(:dropdown) do
    described_class.new(self, course, group, participation)
  end

  subject { Capybara.string(dropdown.to_s) }

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  it "only renders leader options for leader" do
    Event::Course::Role::Leader.create!(participation: participation)
    is_expected.to have_content "E-Mail senden"

    expect(menu).to have_link "Kurs: E-Mail Reminder Kursleitung"
    expect(menu).not_to have_link "Kurs: E-Mail Abmeldung"
  end

  it "only renders participant options for participant" do
    is_expected.to have_content "E-Mail senden"

    expect(menu).not_to have_link "Kurs: E-Mail Reminder Kursleitung"
    expect(menu).to have_link "Kurs: E-Mail Abmeldung"
  end
end
