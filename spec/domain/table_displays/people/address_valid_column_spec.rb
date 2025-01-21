# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::AddressValidColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
  end

  context "valid address" do
    it_behaves_like "table display", {
      column: :address_valid,
      header: "Adresse gültig",
      value: "ja",
      permission: :show
    }
  end

  context "invalid address" do
    before do
      ActsAsTaggableOn::Tagging.create!(taggable: people(:mitglied), tag: PersonTags::Validation.address_invalid(create: true), context: :tags)
    end

    it_behaves_like "table display", {
      column: :address_valid,
      header: "Adresse gültig",
      value: "nein",
      permission: :show
    }
  end
end
