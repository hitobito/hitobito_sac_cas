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
    allow(component).to receive(:link_person?).and_return(true)
    rendered_component = render_inline(component).to_html.squish
    expect(
      rendered_component
    ).to include(
      '<a data-turbo-frame="_top" href="/de/people/600002">Tenzing Norgay</a></strong> (25)'
    )

    expect(
      rendered_component
    ).to have_text 'Tenzing Norgay'
  end

  it 'renders a person in the household without link' do
    allow(component).to receive(:link_person?).and_return(false)
    rendered_component = render_inline(component).to_html.squish

    expect(
      rendered_component
    ).to include(
      '<strong>Frieda Norgay</strong> (25)'
    )

    expect(rendered_component).to have_text('Frieda Norgay (25)')
  end

  it 'renders all people in the household with ages' do
    allow(component).to receive(:link_person?).and_return(false)
    rendered_component = render_inline(component).to_html.squish
    expect(rendered_component).to have_text('Tenzing Norgay (25)')
    expect(rendered_component).to have_text('Frieda Norgay (25)')
    expect(rendered_component).to have_text('Nima Norgay (10)')
  end
end
