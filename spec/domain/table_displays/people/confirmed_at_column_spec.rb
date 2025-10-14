# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::ConfirmedAtColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    # rubocop:todo Layout/LineLength
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
    # rubocop:enable Layout/LineLength
    people(:mitglied).update_column(:confirmed_at, Time.zone.local(2015, 1, 1))
  end

  it_behaves_like "table display", {
    column: :confirmed_at,
    header: "E-Mail bestätigt am",
    value: "01.01.2015",
    permission: :show_full
  }
end
