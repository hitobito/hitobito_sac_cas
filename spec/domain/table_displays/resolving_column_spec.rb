# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe TableDisplays::ResolvingColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied) }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }
  let(:parent) { Group.new(id: 1) }

  before do
    allow(view).to receive(:parent).at_least(:once).and_return(parent)
  end

  it_behaves_like "table display", {
    column: :beitragskategorie,
    header: "Beitragskategorie",
    value: "Einzel",
    permission: :show_full
  }

  it_behaves_like "table display", {
    column: :membership_years,
    header: "Anzahl Mitglieder-Jahre",
    value: "3",
    permission: :show
  } do
    let(:person) { people(:admin).tap { |p| allow(p).to receive(:membership_years).and_return(3) } }
  end

  it_behaves_like "table display", {
    column: :sac_remark_national_office,
    header: "Bemerkungen Geschäftsstelle",
    value: "Remark",
    permission: :manage_national_office_remark
  } do
    let(:person) do
      people(:admin).tap do |p|
        allow(p).to receive(:sac_remark_national_office).and_return("Remark")
      end
    end
  end

  it_behaves_like "table display", {
    column: :sac_remark_section_1,
    header: "Bemerkungen Sektion 1",
    value: "Remark",
    permission: :manage_section_remarks
  } do
    let(:person) do
      people(:admin).tap do |person|
        person.roles.create!(
          group: groups(:matterhorn_funktionaere),
          type: Group::SektionsFunktionaere::Administration.sti_name
        )
        allow(person).to receive(:sac_remark_section_1).and_return("Remark")
      end
    end
  end
end
