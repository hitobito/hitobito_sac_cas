# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "memberships/undo_terminations/new.html.haml", versioning: true do
  include FormatHelper
  before { PaperTrail.request.controller_info = {mutation_id: Random.uuid} }

  def terminate(role, terminate_on: Date.current.yesterday)
    role = roles(role) if role.is_a?(Symbol)
    termination = Memberships::TerminateSacMembership.new(
      role, terminate_on, termination_reason_id: termination_reasons(:deceased).id
    )
    expect(termination).to be_valid
    termination.save!
    role.reload
  end

  let(:undo_termination) { Memberships::UndoTermination.new(role) }

  let(:dom) {
    render
    Capybara::Node::Simple.new(@rendered)
  }

  before do
    assign(:undo_termination, undo_termination)
    assign(:role, role)
    assign(:group, role.group)
    assign(:person, role.person)
  end

  context "with validation errors" do
    let(:role) { roles(:mitglied) }

    it "renders error messages" do
      terminate(role) # terminates role per yesterday
      # create new role starting today so undoing the termination will be invalid (date collision)
      Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
        person: role.person,
        group: role.group,
        start_on: Date.current)

      expect(undo_termination).not_to be_valid
      render

      expect(dom).to have_selector("#error_explanation ul")
      within("#error_explanation") do |alert|
        expect(alert).to have_text(/Person ist bereits Mitglied/)
      end
    end
  end

  context "for single adult memberhsip" do
    let(:role) { roles(:mitglied) }

    it "shows role to be restored" do
      terminate(role)

      expect(dom).to have_text role.person.full_name
      expect(dom).to have_text role.decorate.name_with_group_and_layer
    end

    it "does not show household key" do
      terminate(role)

      expect(dom).to have_no_text "Familiennummer"
    end
  end

  context "for family memberhsip" do
    let(:role) { roles(:familienmitglied) }
    let(:kind_role) { roles(:familienmitglied_kind) }

    it "shows all family roles to be restored" do
      terminate(role)

      expect(dom).to have_text role.person.full_name
      expect(dom).to have_text role.decorate.name_with_group_and_layer

      expect(dom).to have_text kind_role.person.full_name
      expect(dom).to have_text kind_role.decorate.name_with_group_and_layer
    end

    it "shows household key" do
      original_household_key = role.person.household_key
      terminate(role)

      expect(dom).to have_text "Familiennummer"
      expect(dom).to have_text original_household_key
    end
  end
end
