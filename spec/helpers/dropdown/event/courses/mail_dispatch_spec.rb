# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::Events::Courses::MailDispatch do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:user) { people(:admin) }
  let(:course) { events(:top_course) }
  let(:group) { groups(:root) }
  let(:dropdown) do
    Dropdown::Events::Courses::MailDispatch.new(self, course, group)
  end

  subject { Capybara.string(dropdown.to_s) }

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  it "renders dropdown with both options when state ready" do
    course.update_column(:state, :ready)
    is_expected.to have_content "Mailversand"

    expect(menu).to have_link "Teilnehmende: Umfrage"
    expect(menu).to have_link "Kursleitung: Vorbereitung abschliessen"
  end

  it "does not have leader reminder option when state closed" do
    course.update_column(:state, :closed)
    is_expected.to have_content "Mailversand"

    expect(menu).to have_link "Teilnehmende: Umfrage"
    expect(menu).not_to have_link "Kursleitung: Vorbereitung abschliessen"
  end
end
