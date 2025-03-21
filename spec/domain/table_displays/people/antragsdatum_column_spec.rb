# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe TableDisplays::People::AntragsdatumColumn, type: :helper do
  include UtilityHelper
  include FormatHelper

  let(:person) { people(:mitglied).decorate }
  let(:ability) { Ability.new(person) }
  let(:table) { StandardTableBuilder.new([person], self) }

  before do
    allow(table).to receive(:template).at_least(:once).and_return(view)
    allow_any_instance_of(ActionView::Base).to receive(:parent).and_return(groups(:bluemlisalp_neuanmeldungen_nv))
    people(:mitglied).roles.destroy_all
    Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name, person: people(:mitglied), group: groups(:bluemlisalp_neuanmeldungen_nv), start_on: Time.zone.today)
  end

  describe "#exclude_attr?" do
    subject(:column) { described_class.new(ability, table: table, model_class: Person) }

    it "is false on SektionsNeuanmeldungenSektion group" do
      expect(column.exclude_attr?(groups(:matterhorn_neuanmeldungen_sektion))).to eq false
    end

    it "is false on SektionsNeuanmeldungenNv group" do
      expect(column.exclude_attr?(groups(:matterhorn_neuanmeldungen_nv))).to eq false
    end

    it "is true on incompatible group" do
      expect(column.exclude_attr?(groups(:bluemlisalp_funktionaere))).to eq true
    end
  end

  it_behaves_like "table display", {
    column: :antragsdatum,
    header: "Antragsdatum",
    value: I18n.l(Time.zone.today),
    permission: :show
  }
end
