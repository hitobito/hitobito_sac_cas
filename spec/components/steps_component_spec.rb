# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe StepsComponent, type: :component do
  let(:partials) { [] }
  let(:header_css) { '.row .step-headers.offset-md-1' }
  subject(:component) { described_class.new(partials: partials, form: :form, step: :step) }

  before do
    allow_any_instance_of(StepsComponent::ContentComponent).to receive(:markup) do |component|
      component.instance_variable_get(:@partial)
    end
  end

  def render(**args)
    render_inline(described_class.new(**args.merge(form: :form)))
  end

  it 'does not render when partials are empty' do
    expect(component).not_to be_render
  end


  it 'does render header and content' do
    html = render(partials: [:main_person], step: 0)
    expect(html).to have_css("#{header_css} li.active a", text: 'Personendaten')
    expect(html).to have_css('.row .step-content.main-person.active', text: 'main_person')
  end

  it 'renders two steps with second one active' do
    html = render(partials: [:main_person, :household], step: 1)

    expect(html).to have_css("#{header_css} li:nth-child(1):not(.active) a", text: 'Personendaten')
    expect(html).to have_css("#{header_css} li:nth-child(2).active a", text: 'Familienmitglieder')
    expect(html).to have_css('.step-content.main-person:not(.active)')
    expect(html).to have_css('.step-content.household.active')
  end

  it 'does render second step as text when on first' do
    html = render(partials: [:main_person, :household], step: 0)
    expect(html).to have_link 'Personendaten'
    expect(html).not_to have_link 'Familienmitglieder'
  end

  describe StepsComponent::ContentComponent do
    let(:form) { double(:form) }
    let(:iterator) { double(:iterator, index: 1) }
    subject(:component) { described_class.new(partial: :partial, partial_iteration: iterator, form: form, step: :step) }

    it 'back link renders link for stimulus controller iterator based index' do
      allow_any_instance_of(StepsComponent::ContentComponent).to receive(:markup) do |component|
        back_link = Capybara::Node::Simple.new(component.back_link)
        expect(back_link).to have_link 'Zurück'
        expect(back_link).to have_css '.link.cancel[data-index=0]', text: 'Zurück'
        expect(back_link).to have_css ".link.cancel[data-action='steps-component#back']", text: 'Zurück'
      end
      render_inline(component)
    end

    it 'next button renders form button with step value' do
      allow_any_instance_of(StepsComponent::ContentComponent).to receive(:markup) do |component|
        expect(form).to receive(:button).with('Weiter', class: 'btn btn-primary', data: { disable_with: 'Weiter' }, name: :step, value: 1)
        component.next_button
      end
      render_inline(component)
    end

    it 'next button accepts specific label' do
      allow_any_instance_of(StepsComponent::ContentComponent).to receive(:markup) do |component|
        expect(form).to receive(:button).with('Test', class: 'btn btn-primary', data: { disable_with: 'Test' }, name: :step, value: 1)
        component.next_button('Test')
      end
      render_inline(component)
    end
  end
end

