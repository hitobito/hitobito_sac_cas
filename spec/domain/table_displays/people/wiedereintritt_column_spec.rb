# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::WiedereintrittColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_mitglieder))
  end

  context "without wiedereintritt" do
    it_behaves_like "table display", {
      column: :wiedereintritt,
      header: "Wiedereintritt",
      value: "nein",
      permission: :show
    }
  end

  context "with wiedereintritt" do
    before do
      people(:mitglied).roles.destroy_all
      Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name, person: people(:mitglied),
        group: groups(:bluemlisalp_neuanmeldungen_nv))
      Fabricate(Group::SektionsMitglieder::Mitglied.name.to_sym, group: groups(:bluemlisalp_mitglieder),
        person: people(:mitglied),
        start_on: Time.zone.local(1990, 1, 1),
        end_on: Time.zone.local(1995, 12, 31))
    end

    it_behaves_like "table display", {
      column: :wiedereintritt,
      header: "Wiedereintritt",
      value: "ja",
      permission: :show
    }
  end
end
