# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::DuplicateExistsColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  context "has person duplicate" do
    before do
      PersonDuplicate.create!(person_1: people(:admin), person_2: people(:mitglied))
    end

    it_behaves_like "table display", {
      column: :duplicate_exists,
      header: "Duplikat existiert",
      value: "ja",
      permission: :show
    }
  end

  context "does not have person duplicate" do
    it_behaves_like "table display", {
      column: :duplicate_exists,
      header: "Duplikat existiert",
      value: "nein",
      permission: :show
    }
  end
end
