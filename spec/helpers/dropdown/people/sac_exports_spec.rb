# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::People::SacExports do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:group) { groups(:bluemlisalp_mitglieder) }

  let(:dropdown) { described_class.new(self, group) }

  subject(:dom) { Capybara.string(dropdown.to_s) }

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  it "has jubilare popover link" do
    jubilare = dom.find_link "Jubilare"
    expect(jubilare["data-anchor"]).to eq "#dropdown_people_sac_exports"
    expect(jubilare["data-bs-toggle"]).to eq "popover"
    expect(jubilare["data-bs-title"]).to eq "Jubilare"
    form = Capybara::Node::Simple.new(jubilare["data-bs-content"])
    expect(form).to have_field "Stichtag"
    expect(form).to have_field "Anzahl Mitgliedsjahre"
  end

  it "has eintritte popover link" do
    jubilare = dom.find_link "Eintritte"
    expect(jubilare["data-anchor"]).to eq "#dropdown_people_sac_exports"
    expect(jubilare["data-bs-toggle"]).to eq "popover"
    expect(jubilare["data-bs-title"]).to eq "Eintritte"
    form = Capybara::Node::Simple.new(jubilare["data-bs-content"])
    expect(form).to have_field "Von"
    expect(form).to have_field "Bis"
  end
end
