# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe MailingListAbility do
  let(:mitglied_with_schreibrecht) do
    Fabricate(
      Group::SektionsMitglieder::Schreibrecht.sti_name.to_sym,
      group: groups(:bluemlisalp_mitglieder)
    ).person
  end

  let(:mitglied_without_schreibrecht) do
    Fabricate(
      Group::SektionsMitglieder::Mitglied.sti_name.to_sym,
      group: groups(:bluemlisalp_mitglieder)
    ).person
  end
  let(:mailing_list) { Fabricate(:mailing_list, group: groups(:bluemlisalp)) }
  let(:mailing_list_in_other_sub_group) { Fabricate(:mailing_list, group: groups(:bluemlisalp_funktionaere)) }
  let(:mailing_list_in_foreign_group) { Fabricate(:mailing_list, group: groups(:matterhorn)) }

  subject(:ability) { Ability.new(person.reload) }

  context "mitglied with Schreibrecht" do
    let(:person) { mitglied_with_schreibrecht }

    it "is permitted to manage main group abos" do
      expect(ability).to be_able_to(:create, mailing_list)
    end

    it "is permitted to manage sub group abos in same main group" do
      expect(ability).to be_able_to(:create, mailing_list_in_other_sub_group)
    end

    it "is denied to manage foreign main group abos" do
      expect(ability).not_to be_able_to(:create, mailing_list_in_foreign_group)
    end
  end

  context "mitglied without Schreibrecht" do
    let(:person) { mitglied_without_schreibrecht }

    it "is denied to manage main group abos" do
      expect(ability).not_to be_able_to(:create, mailing_list)
    end
  end
end
