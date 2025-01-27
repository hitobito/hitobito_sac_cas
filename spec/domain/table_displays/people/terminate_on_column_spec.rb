# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::TerminateOnColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    people(:mitglied).roles_unscoped.destroy_all
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
  end

  def create_membership_role(start_on, end_on)
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym, group: groups(:bluemlisalp_mitglieder),
      person: people(:mitglied),
      start_on: start_on,
      end_on: end_on)
  end

  context "only having active role" do
    before do
      create_membership_role(1.year.ago, 1.year.from_now)
    end

    it_behaves_like "table display", {
      column: :terminate_on,
      header: "Austrittsdatum",
      value: "",
      permission: :show_full
    }
  end

  context "with ended roles" do
    before do
      create_membership_role(2.years.ago, 1.years.ago)
    end

    it_behaves_like "table display", {
      column: :terminate_on,
      header: "Austrittsdatum",
      value: I18n.l(1.year.ago.to_date),
      permission: :show_full
    }
  end

  context "with multiple ended roles" do
    before do
      create_membership_role(11.years.ago, 10.years.ago)
      create_membership_role(6.years.ago, 5.years.ago)
    end

    it_behaves_like "table display", {
      column: :terminate_on,
      header: "Austrittsdatum",
      value: I18n.l(5.year.ago.to_date),
      permission: :show_full
    }
  end

  context "with ended role and active membership role" do
    before do
      create_membership_role(3.years.ago, 2.years.ago)
      create_membership_role(1.year.ago, 1.year.from_now)
    end

    it_behaves_like "table display", {
      column: :terminate_on,
      header: "Austrittsdatum",
      value: "",
      permission: :show_full
    }
  end
end
