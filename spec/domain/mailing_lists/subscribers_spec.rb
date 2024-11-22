# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe MailingLists::Subscribers do
  include Subscriptions::SpecHelper

  let!(:list) {
    Fabricate(:mailing_list,
      group:,
      subscribable_for: "configured",
      subscribable_mode: "opt_out")
  }
  let!(:subscription) do
    Fabricate(:subscription,
      mailing_list: list,
      subscriber: group,
      role_types: [mitglied, mitglied_zusatzsektion, schreibrecht])
  end

  let(:test_person) { create_person(30) }

  subject(:entries) { MailingLists::Subscribers.new(list).people }

  def group_id = group.id

  def set_filter(filter)
    list.update!(filter_chain: filter)
  end

  def create_person(age = 30, **attrs) = Fabricate(:person, birthday: age.years.ago, **attrs)

  def create_role(type, group, person = test_person, **attrs)
    Fabricate(type.sti_name, group: groups(group), person: person, **attrs)
  end

  def mitglied = Group::SektionsMitglieder::Mitglied

  def mitglied_zusatzsektion = Group::SektionsMitglieder::MitgliedZusatzsektion

  def schreibrecht = Group::SektionsMitglieder::Schreibrecht

  context "invoice_receiver filter" do
    context "with list in top layer" do
      let(:group) { groups(:root) }

      context "with invoice_receiver stammsektion filter" do
        before { set_filter(invoice_receiver: {stammsektion: true, group_id:}) }

        it "includes member in a sektion" do
          create_role(mitglied, :bluemlisalp_mitglieder)
          expect(entries).to include(test_person)
        end

        it "excludes person with non-member role" do
          create_role(schreibrecht, :bluemlisalp_mitglieder)
          expect(entries).not_to include(test_person)
        end
      end

      context "with invoice_receiver zusatzsektion filter" do
        before { set_filter(invoice_receiver: {zusatzsektion: true, group_id:}) }

        it "includes member in a zusatzsektion" do
          create_role(mitglied, :bluemlisalp_mitglieder)
          create_role(mitglied_zusatzsektion, :matterhorn_mitglieder)
          expect(entries).to include(test_person)
        end

        it "excludes member without zusatzsektion" do
          create_role(mitglied, :bluemlisalp_mitglieder)
          expect(entries).not_to include(test_person)
        end
      end

      context "with both invoice_receiver filters stammsektion and zusatzsektion" do
        before { set_filter(invoice_receiver: {stammsektion: true, zusatzsektion: true, group_id:}) }

        it "includes member in a sektion" do
          create_role(mitglied, :bluemlisalp_mitglieder)
          expect(entries).to include(test_person)
        end

        it "includes member in a zusatzsektion" do
          create_role(mitglied, :bluemlisalp_mitglieder)
          create_role(mitglied_zusatzsektion, :matterhorn_mitglieder)
          expect(entries).to include(test_person)
        end

        it "excludes person with non-member role" do
          create_role(schreibrecht, :bluemlisalp_mitglieder)
          expect(entries).not_to include(test_person)
        end
      end
    end

    context "with list in sublayer" do
      let(:group) { groups(:bluemlisalp) }

      context "with invoice_receiver stammsektion filter" do
        before { set_filter(invoice_receiver: {stammsektion: true, group_id:}) }

        it "includes member in same layer" do
          create_role(mitglied, :bluemlisalp_mitglieder)
          expect(entries).to include(test_person)
        end

        it "excludes member in a lower layer" do
          create_role(mitglied, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
          expect(entries).not_to include(test_person)
        end

        it "excludes member in a different layer" do
          create_role(mitglied, :matterhorn_mitglieder)
          expect(entries).not_to include(test_person)
        end
      end

      context "with invoice_receiver zusatzsektion filter" do
        before { set_filter(invoice_receiver: {zusatzsektion: true, group_id:}) }

        it "includes zusatzsektion member in same layer" do
          create_role(mitglied, :matterhorn_mitglieder)
          create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder)
          expect(entries).to include(test_person)
        end

        it "excludes zusatzsektion member in a lower layer" do
          create_role(mitglied, :matterhorn_mitglieder)
          create_role(mitglied_zusatzsektion, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
          expect(entries).not_to include(test_person)
        end

        it "excludes zusatzsektion member in a different layer" do
          create_role(mitglied, :bluemlisalp_mitglieder)
          create_role(mitglied_zusatzsektion, :matterhorn_mitglieder)
          expect(entries).not_to include(test_person)
        end
      end

      context "with both invoice_receiver filters stammsektion and zusatzsektion" do
        before { set_filter(invoice_receiver: {stammsektion: true, zusatzsektion: true, group_id:}) }

        it "includes member in same layer" do
          create_role(mitglied, :bluemlisalp_mitglieder)
          expect(entries).to include(test_person)
        end

        it "includes zusatzsektion member in same layer" do
          create_role(mitglied, :matterhorn_mitglieder)
          create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder)
          expect(entries).to include(test_person)
        end
      end
    end
  end
end
