# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::SacRemarkSectionColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(people(:admin)) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
    people(:mitglied).update_column(:sac_remark_section_1, "Bemerkung von Sektion 1")
    people(:mitglied).update_column(:sac_remark_section_2, "Bemerkung von Sektion 2")
    people(:mitglied).update_column(:sac_remark_section_3, "Bemerkung von Sektion 3")
    people(:mitglied).update_column(:sac_remark_section_4, "Bemerkung von Sektion 4")
    people(:mitglied).update_column(:sac_remark_section_5, "Bemerkung von Sektion 5")
  end

  it_behaves_like "table display", {
    column: :sac_remark_section_1,
    header: "Bemerkungen Sektion 1",
    value: "Bemerkung von Sektion 1",
    permission: :manage_section_remarks
  }

  it_behaves_like "table display", {
    column: :sac_remark_section_2,
    header: "Bemerkungen Sektion 2",
    value: "Bemerkung von Sektion 2",
    permission: :manage_section_remarks
  }

  it_behaves_like "table display", {
    column: :sac_remark_section_3,
    header: "Bemerkungen Sektion 3",
    value: "Bemerkung von Sektion 3",
    permission: :manage_section_remarks
  }

  it_behaves_like "table display", {
    column: :sac_remark_section_4,
    header: "Bemerkungen Sektion 4",
    value: "Bemerkung von Sektion 4",
    permission: :manage_section_remarks
  }

  it_behaves_like "table display", {
    column: :sac_remark_section_5,
    header: "Bemerkungen Sektion 5",
    value: "Bemerkung von Sektion 5",
    permission: :manage_section_remarks
  }
end
