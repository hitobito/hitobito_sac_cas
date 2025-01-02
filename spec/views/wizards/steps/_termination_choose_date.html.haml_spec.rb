#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "wizards/steps/_termination_choose_date.html.haml" do
  include FormatHelper

  let(:person) { people(:mitglied) }
  let(:wizard) { Wizards::Memberships::TerminateSacMembershipWizard.new(person: person) }
  let(:form_builder) { StandardFormBuilder.new(:wizard, wizard, view, {}) }
  let(:iterator) { double(:iterator, index: 0, last?: false) }
  let(:steps_component) { StepsComponent::ContentComponent.new(partial: :partial, partial_iteration: iterator, form: form_builder, step: 0) }
  let(:end_on) { I18n.l(roles(:mitglied).end_on) }
  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    allow_any_instance_of(StepsComponent::ContentComponent).to receive(:fields_for).and_return([])
    allow(view).to receive_messages(c: steps_component)
    allow(view).to receive_messages(wizard: wizard)
  end

  it "renders warning when role is already terminated" do
    person.sac_membership.stammsektion_role.update_column(:terminated, true)
    expect(dom).to have_text "Achtung: Die Mitgliedschaft ist bereits gekündigt per #{end_on}"
  end

  it "does not render warning when role is not terminated" do
    expect(dom).not_to have_text "Achtung: Die Mitgliedschaft ist bereits gekündigt per #{end_on}"
  end
end
