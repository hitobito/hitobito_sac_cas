# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe HouseholdAsideMemberComponent, type: :component do
  let(:familienmitglied) { people(:familienmitglied) }
  let(:familienmitglied2) { people(:familienmitglied2) }
  let(:familienmitglied_kind) { people(:familienmitglied_kind) }
  subject(:component) { described_class.new(person: familienmitglied) }

  it 'renders a person in the household with link' do
    stub_can(:show, true)
    stub_can(:set_sac_family_main_person, true)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_selector('a[data-turbo-frame="_top"][href="/de/people/600002"]', text: 'Tenzing Norgay')
    expect(rendered_component).to have_selector('span', text: '(25)')
    expect(rendered_component).to have_text 'Tenzing Norgay'
  end

  it 'renders a person in the household without link' do
    stub_can(:show, false)
    stub_can(:set_sac_family_main_person, false)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_selector('strong', text: 'Frieda Norgay')
    expect(rendered_component).to have_selector('span', text: '(25)')
    expect(rendered_component).to have_text('Frieda Norgay (25)')
  end

  it 'renders all people in the household with ages' do
    stub_can(:show, false)
    stub_can(:set_sac_family_main_person, false)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_text('Tenzing Norgay (25)')
    expect(rendered_component).to have_text('Frieda Norgay (25)')
    expect(rendered_component).to have_text('Nima Norgay (10)')
  end

  it 'renders people with main person link' do
    stub_can(:show, true)
    stub_can(:set_sac_family_main_person, true)
    rendered_component = render_inline(component)
    expect(rendered_component).to have_selector('td', text: 'Tenzing Norgay') do |a|
      expect(a.ancestor('tr')).to have_selector('span[title="Familienrechnungsempfänger"]')
    end
    expect(rendered_component).to have_selector('td a', text: 'Frieda Norgay') do |a|
      expect(a.ancestor('tr')).to have_selector('a[title="Zum Familienrechnungsempfänger machen"]')
    end

    expect(rendered_component).to have_selector('td a', text: 'Nima Norgay') do |a|
      expect(a.ancestor('tr')).not_to have_selector('span[title="Familienrechnungsempfänger"]')
      expect(a.ancestor('tr')).not_to have_selector('a[title="Zum Familienrechnungsempfänger machen"]')
    end
  end

  private

  def stub_can(permission, result)
    allow(component).to receive(:can?).with(permission, anything).and_return(result)
  end
end
