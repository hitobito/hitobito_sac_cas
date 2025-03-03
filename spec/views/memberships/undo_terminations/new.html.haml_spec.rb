# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe "memberships/undo_terminations/new.html.haml", versioning: true do
  include FormatHelper
  before { PaperTrail.request.controller_info = {mutation_id: Random.uuid} }

  def update_terminated!(role, value)
    # monkey dance required because directly assigning terminated intentionally raises error
    role = roles(role) if role.is_a?(Symbol)
    role.tap { _1.write_attribute(:terminated, value) }.save!
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
    # allow(view).to receive_messages(entry: kind, )
  end

  context "for single adult memberhsip" do
    let(:role) { roles(:mitglied) }

    it "shows role to be restored" do
      update_terminated!(role, true)

      expect(dom).to have_text role.person.full_name
      expect(dom).to have_text role.decorate.name_with_group_and_layer
    end

    it "does not show household key" do
      update_terminated!(role, true)

      expect(dom).to have_no_text "Familiennummer"
    end
  end

  context "for family memberhsip" do
    let(:role) { roles(:familienmitglied) }
    let(:kind_role) { roles(:familienmitglied_kind) }

    it "shows all family roles to be restored" do
      update_terminated!(role, true)
      update_terminated!(kind_role, true)

      expect(dom).to have_text role.person.full_name
      expect(dom).to have_text role.decorate.name_with_group_and_layer

      expect(dom).to have_text kind_role.person.full_name
      expect(dom).to have_text kind_role.decorate.name_with_group_and_layer
    end

    it "shows household key" do
      original_household_key = role.person.household_key
      update_terminated!(role, true)
      update_terminated!(kind_role, true)

      expect(dom).to have_text "Familiennummer"
      expect(dom).to have_text original_household_key
    end
  end
end
