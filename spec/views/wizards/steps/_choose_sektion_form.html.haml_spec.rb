# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'wizards/steps/_choose_sektion_form.html.haml' do
  let(:wizard) { Wizards::Base.new(current_step: 0) }
  let(:params) { {} }
  let(:step) { Wizards::Steps::ChooseSektionForm.new(wizard, **params) }
  let(:form) { StandardFormBuilder.new(:wizard, wizard, view, { builder: StandardFormBuilder }) }

  let(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    allow(Wizards::Base).to receive(:steps).and_return([step.class])
    allow(view).to receive_messages(f: form,
                                    c: instance_double(
                                      StepsComponent::ContentComponent, index: 0
                                    ))
  end

  it 'renders field with group options' do
    expect(dom).to have_select 'Sektion wählen',
                               options: [
                                 'Bitte wählen',
                                 'SAC Blüemlisalp Ausserberg',
                                 'SAC Blüemlisalp',
                                 'SAC Matterhorn'
                               ]
  end

  it 'autosubmits field' do
    field = dom.find_field 'Sektion wählen'
    expect(field.native['data-action']).to eq 'change->autosubmit#save'
  end
end
