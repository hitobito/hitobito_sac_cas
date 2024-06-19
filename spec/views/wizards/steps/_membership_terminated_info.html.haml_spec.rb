# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe 'wizards/steps/_membership_terminated_info.html.haml' do
  let(:wizard) { Wizards::Base.new(current_step: 0) }
  let(:params) { {} }
  let(:step) { Wizards::Steps::MembershipTerminatedInfo.new(wizard, **params) }
  let(:component) do
    StepsComponent::ContentComponent.new(
      partial: :choose_sektion,
      partial_iteration: double(:iter, index: 0),
      step: step,
      form: form
    )
  end
  let(:form) { StandardFormBuilder.new(:wizard, wizard, view, { builder: StandardFormBuilder }) }

  let(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    allow(Wizards::Base).to receive(:steps).and_return([step.class])
    allow(view).to receive_messages(f: form, c: component)
  end

  it 'renders' do
    expect(dom).to have_text('Deine Mitgliedschaft ist gekündigt per ')
  end
end
