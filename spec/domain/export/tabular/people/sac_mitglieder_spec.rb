# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Export::Tabular::People::SacMitglieder do
  let(:group) { groups(:bluemlisalp) }

  subject(:tabular) { described_class.new(group) }

  its(:model_class) { is_expected.to eq Person }
  its(:row_class) { is_expected.to eq Export::Tabular::People::SacMitgliedRow }

  it "#new with group other than Sektion or Ortsgruppe raises ArgumentError" do
    expect { described_class.new(groups(:bluemlisalp_mitglieder)) }
      .to raise_error(ArgumentError, "Argument must be a Sektion or Ortsgruppe")
  end

  it "#labels is nil" do
    expect(tabular.labels).to be_nil
  end

  it "#attributes" do
    expect(tabular.attributes).to eq(
      [
        :id,
        :layer_navision_id_padded,
        :last_name,
        :first_name,
        :adresszusatz,
        :address,
        :postfach,
        :zip_code,
        :town,
        :country,
        :birthday,
        :phone_number_main,
        :phone_number_privat,
        :empty, # 1 leere Spalte
        :phone_number_mobil,
        :phone_number_fax,
        :email,
        :gender,
        :empty, # 1 leere Spalte
        :language,
        :eintrittsjahr,
        :begünstigt,
        :ehrenmitglied,
        :beitragskategorie,
        :s_info_1,
        :s_info_2,
        :s_info_3,
        :bemerkungen,
        :saldo,
        :empty, # 1 leere Spalte
        :anzahl_die_alpen,
        :anzahl_sektionsbulletin
      ]
    )
  end

  describe "#list" do
    context "all mitglieder of the layer" do
      it "are included" do
        expect(tabular.list).to contain_exactly(
          roles(:mitglied).person,
          roles(:familienmitglied).person,
          roles(:familienmitglied2).person,
          roles(:familienmitglied_kind).person
        )
      end

      it "former mitglieder are not included" do
        roles(:mitglied).update!(end_on: 1.day.ago)
        expect(tabular.list).to contain_exactly(
          roles(:familienmitglied).person,
          roles(:familienmitglied2).person,
          roles(:familienmitglied_kind).person
        )
      end
    end

    context "zusatzsektion mitglieder of the layer" do
      it "are included" do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:matterhorn_mitglieder), person: people(:abonnent))
        Fabricate(Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name,
          group: groups(:bluemlisalp_mitglieder), person: people(:abonnent))

        expect(tabular.list).to include people(:abonnent)
      end
    end

    context "mitglieder of descendent layer" do
      it "are not included" do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: people(:abonnent))
        expect(tabular.list).not_to include people(:abonnent)
      end
    end

    context "mitglieder of ancestor layer" do
      let(:group) { groups(:bluemlisalp_ortsgruppe_ausserberg) }

      it "are not included" do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
          person: people(:abonnent))
        expect(tabular.list).to contain_exactly people(:abonnent)
      end
    end

    context "mitglieder of sibling layer" do
      it "are not included" do
        Fabricate(Group::SektionsMitglieder::Mitglied.sti_name,
          group: groups(:matterhorn_mitglieder),
          person: people(:abonnent))
        expect(tabular.list).not_to include people(:abonnent)
      end
    end
  end

  describe "#data_rows" do
    it "does not do N+1" do
      # Expected 7 queries:
      # - 1 for loading the group
      # - 1 for loading the groups children
      # - 1 for loading all people
      # - 1 for loading their phone numbers
      # - 1 for loading the people's roles_unscoped
      # - 1 for loading the people's roles
      # - 1 for loading the people's roles' groups
      expect_query_count do
        # make sure we have more than one row for the test to be meaningful
        expect(tabular.data_rows.to_a).to have_at_least(2).items
      end.to eq 7
    end
  end
end
