# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::SacRemarkNationalOfficeColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(people(:admin)) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    # rubocop:todo Layout/LineLength
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
    # rubocop:enable Layout/LineLength
    people(:mitglied).update_column(:sac_remark_national_office, "Bemerkung von Geschäfststelle")
  end

  it_behaves_like "table display", {
    column: :sac_remark_national_office,
    header: "Bemerkungen Geschäftsstelle",
    value: "Bemerkung von Geschäfststelle",
    permission: :manage_national_office_remark
  }
end
