# encoding: utf-8

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'
describe 'shared/_register_on_fields.html.haml' do

  let(:group) { groups(:bluemlisalp_mitglieder) }
  let(:current_user) { people(:top_leader) }
  let(:model) { SelfInscription.new(group: group, person: Person.new) }
  let(:form_builder) { StandardFormBuilder.new(:group, model, view, {}) }
  let(:dom) { Capybara::Node::Simple.new(@rendered)  }

  before do
    allow(view).to receive_messages(current_user: Person.new)
    allow(view).to receive_messages(entry: GroupDecorator.decorate(group))
    allow(controller).to receive_messages(current_user: Person.new)
    allow(controller).to receive_messages(f: form_builder)
    assign(:sub_groups, 'Gruppen' => [], 'Untergruppen' => [])
    assign(:group, group)
  end

  it 'renders now and july checkboxes in june' do
    travel_to(Time.zone.local(2024, 6, 30)) do
      render partial: 'shared/register_on_fields', formats: [:html], locals: { f: form_builder }
    end
    expect(dom).to have_checked_field 'sofort'
    expect(dom).to have_unchecked_field '01. Juli'
    expect(dom).not_to have_field '01. Oktober'
  end

  it 'renders now and oct checkboxes in july' do
    travel_to(Time.zone.local(2024, 7, 1)) do
      render partial: 'shared/register_on_fields', formats: [:html], locals: { f: form_builder }
    end
    expect(dom).to have_checked_field 'sofort'
    expect(dom).to have_unchecked_field '01. Oktober'
    expect(dom).not_to have_field '01. Juli'
  end

  it 'renders no checkboxes but label in october' do
    travel_to(Time.zone.local(2024, 10, 1)) do
      render partial: 'shared/register_on_fields', formats: [:html], locals: { f: form_builder }
    end
    expect(dom).to have_css('.row:nth-of-type(1) .col-md-2',  text: 'Eintrittsdatum per')
    expect(dom).to have_css('.row:nth-of-type(1) .col-md',  text: 'sofort')
    expect(dom).not_to have_field '01. Juli'
    expect(dom).not_to have_field '01. Oktober'
    expect(dom).not_to have_field 'sofort'
  end
end

