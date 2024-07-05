# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "wizards/steps/_main_email.html.haml" do
  let(:wizard) { Wizards::Base.new(current_step: 0) }
  let(:step) { Wizards::Steps::MainEmail.new(wizard) }
  let(:form) { StandardFormBuilder.new(:wizard, wizard, view, {builder: StandardFormBuilder}) }
  let(:content_component) do
    StepsComponent::ContentComponent.new(
      partial: :main_email,
      partial_iteration: double(:iter, index: 0),
      step: step,
      form: form
    )
  end

  let(:dom) do
    render
    Capybara::Node::Simple.new(@rendered)
  end

  before do
    allow(Wizards::Base).to receive(:steps).and_return([step.class])
    allow(view).to receive_messages(
      f: form,
      c: content_component
    )
  end

  it "renders email field" do
    expect(dom).to have_field "Haupt-E-Mail"
  end
end
