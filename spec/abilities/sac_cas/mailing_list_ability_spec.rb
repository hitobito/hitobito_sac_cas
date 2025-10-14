# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe MailingListAbility do
  let(:mitglied_without_schreibrecht) do
    Fabricate(
      Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
      group: groups(:bluemlisalp_mitglieder)
    ).person
  end
  let(:mailing_list) { Fabricate(:mailing_list, group: groups(:bluemlisalp)) }
  let(:mailing_list_in_other_sub_group) { Fabricate(:mailing_list, group: groups(:bluemlisalp_touren_und_kurse)) }
  let(:mailing_list_in_foreign_group) { Fabricate(:mailing_list, group: groups(:matterhorn)) }

  subject(:ability) { Ability.new(person.reload) }

  [[Group::SektionsFunktionaere::Redaktion, :bluemlisalp_funktionaere],
    [Group::SektionsFunktionaere::Mitgliederverwaltung, :bluemlisalp_funktionaere],
    [Group::SektionsMitglieder::Leserecht, :bluemlisalp_mitglieder],
    [Group::SektionsMitglieder::Schreibrecht, :bluemlisalp_mitglieder]].each do |role_type, group_key|
    context "mitglied with #{role_type}" do
      let(:person) { mitglied_with_schreibrecht }
      let(:mitglied_with_schreibrecht) do
        Fabricate(
          role_type.sti_name.to_sym,
          group: groups(group_key)
        ).person
      end

      it "is permitted to show layer abos" do
        expect(ability).to be_able_to(:show, mailing_list)
        expect(ability).to be_able_to(:index_subscriptions, mailing_list)
        expect(ability).to be_able_to(:export_subscriptions, mailing_list)
      end

      it "is permitted to manage sub group abos in same layer" do
        expect(ability).to be_able_to(:show, mailing_list_in_other_sub_group)
        expect(ability).to be_able_to(:index_subscriptions, mailing_list_in_other_sub_group)
        expect(ability).to be_able_to(:export_subscriptions, mailing_list_in_other_sub_group)
      end

      it "is denied to manage foreign layer abos" do
        expect(ability).not_to be_able_to(:show, mailing_list_in_foreign_group)
        expect(ability).not_to be_able_to(:index_subscriptions, mailing_list_in_foreign_group)
        expect(ability).not_to be_able_to(:export_subscriptions, mailing_list_in_foreign_group)
      end
    end
  end

  context "mitglied without Schreibrecht" do
    let(:person) { mitglied_without_schreibrecht }

    it "is denied to manage layer abos" do
      expect(ability).not_to be_able_to(:create, mailing_list)
    end
  end
end
