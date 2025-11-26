# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::TerminationReasonColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    people(:mitglied).roles_unscoped.destroy_all
    allow_any_instance_of(ActionView::Base)
      .to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
  end

  def create_membership_role(start_on, end_on)
    Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym,
      group: groups(:bluemlisalp_mitglieder),
      person: people(:mitglied),
      start_on: start_on,
      end_on: end_on,
      termination_reason_id: TerminationReason.first.id)
  end

  def create_terminated_membership_role(start_on, end_on)
    create_membership_role(start_on, 1.day.from_now).tap do |role|
      Roles::Termination.new(role:, terminate_on: end_on, validate_terminate_on: false).call
    end
  end

  context "only having active role" do
    before do
      create_membership_role(1.year.ago, 1.year.from_now)
    end

    it_behaves_like "table display", {
      column: :termination_reason,
      header: "Austrittsgrund",
      value: "",
      permission: :show_full
    }
  end

  context "with recently terminated role" do
    before do
      create_terminated_membership_role(2.years.ago, 11.months.ago)
    end

    it_behaves_like "table display", {
      column: :termination_reason,
      header: "Austrittsgrund",
      value: "Umgezogen",
      permission: :show_full
    }
  end

  context "with terminated role in the future" do
    before do
      create_terminated_membership_role(2.years.ago, 11.months.from_now)
    end

    it_behaves_like "table display", {
      column: :termination_reason,
      header: "Austrittsgrund",
      value: "Umgezogen",
      permission: :show_full
    }
  end

  context "with long ago terminated role" do
    before do
      create_terminated_membership_role(20.years.ago, 5.years.ago)
    end

    it_behaves_like "table display", {
      column: :terminate_on,
      header: "Austrittsdatum",
      value: "",
      permission: :show_full
    }
  end

  context "with multiple terminated roles" do
    before do
      create_terminated_membership_role(11.years.ago, 10.years.ago)
      create_terminated_membership_role(6.years.ago, 5.months.ago)
    end

    it_behaves_like "table display", {
      column: :termination_reason,
      header: "Austrittsgrund",
      value: "Umgezogen",
      permission: :show_full
    }
  end

  context "with terminated role and active membership role" do
    before do
      create_terminated_membership_role(3.years.ago, 2.years.ago)
      create_membership_role(1.year.ago, 1.year.from_now)
    end

    it_behaves_like "table display", {
      column: :termination_reason,
      header: "Austrittsgrund",
      value: "",
      permission: :show_full
    }
  end
end
