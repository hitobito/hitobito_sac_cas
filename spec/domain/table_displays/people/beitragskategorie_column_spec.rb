# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::BeitragskategorieColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
  end

  context "adult" do
    let(:person) { people(:mitglied).decorate }

    it_behaves_like "table display", {
      column: :beitragskategorie,
      header: "Beitragskategorie",
      value: "Einzel",
      permission: :show_full
    }
  end

  context "family" do
    let(:person) { people(:familienmitglied).decorate }

    it_behaves_like "table display", {
      column: :beitragskategorie,
      header: "Beitragskategorie",
      value: "Familie",
      permission: :show_full
    }
  end

  context "youth" do
    let(:person) { people(:mitglied).decorate }

    before do
      people(:mitglied).roles.update_all(beitragskategorie: "youth")
    end

    it_behaves_like "table display", {
      column: :beitragskategorie,
      header: "Beitragskategorie",
      value: "Jugend",
      permission: :show_full
    }
  end
end
