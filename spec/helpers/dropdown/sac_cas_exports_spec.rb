# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Dropdown::SacCasExports do
  include Rails.application.routes.url_helpers
  include FormatHelper
  include LayoutHelper
  include UtilityHelper

  let(:group) { groups(:root) }

  let(:dropdown) { described_class.new(self, group) }

  subject(:dom) { Capybara.string(dropdown.to_s) }

  def menu = subject.find(".btn-group > ul.dropdown-menu")

  it "has sac statistics popover link" do
    item = dom.find_link "SAC Statistik"
    expect(item["data-anchor"]).to eq "#dropdown_sac_cas_exports"
    expect(item["data-bs-toggle"]).to eq "popover"
    expect(item["data-bs-title"]).to eq "SAC Statistik"
    form = Capybara::Node::Simple.new(item["data-bs-content"])
    expect(form).to have_field "Von"
    expect(form).to have_field "Bis"
  end

  it "has alps recipients popover link" do
    item = dom.find_link "Die Alpen: Empfängerlisten"
    expect(item["data-anchor"]).to eq "#dropdown_sac_cas_exports"
    expect(item["data-bs-toggle"]).to eq "popover"
    expect(item["data-bs-title"]).to eq "Die Alpen: Empfängerlisten"
    form = Capybara::Node::Simple.new(item["data-bs-content"])
    expect(form).to have_field "Stichtag"
    expect(form).to have_field "Neueintritte ab"
  end

  it "has sac courses popover link" do
    item = dom.find_link "Finanzindikatoren Kurse"
    expect(item["data-anchor"]).to eq "#dropdown_sac_cas_exports"
    expect(item["data-bs-toggle"]).to eq "popover"
    expect(item["data-bs-title"]).to eq "Finanzindikatoren Kurse"
    form = Capybara::Node::Simple.new(item["data-bs-content"])
    expect(form).to have_field "Jahr"
  end
end
