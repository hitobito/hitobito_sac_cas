# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::AntragFuerColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  context "stammsektion" do
    before do
      allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_neuanmeldungen_nv))
      people(:mitglied).roles.destroy_all
      Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name, person: people(:mitglied), group: groups(:bluemlisalp_neuanmeldungen_nv))
    end

    it_behaves_like "table display", {
      column: :antrag_fuer,
      header: "Antrag für",
      value: "Stammsektion",
      permission: :show
    }
  end

  context "zusatzsektion" do
    before do
      allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:matterhorn_neuanmeldungen_nv))
      people(:mitglied).sac_membership.zusatzsektion_roles.destroy_all
      Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name, person: people(:mitglied), group: groups(:matterhorn_neuanmeldungen_nv), end_on: 2.days.from_now)
    end

    it_behaves_like "table display", {
      column: :antrag_fuer,
      header: "Antrag für",
      value: "Zusatzsektion",
      permission: :show
    }
  end
end
