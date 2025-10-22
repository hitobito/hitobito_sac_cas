# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Person::Filter::InvoiceReceiver do
  let(:user) { people(:admin) }
  let(:filter) { described_class.new("attr", filter_args) }

  subject(:entries) { filter.apply(Person.select(:id)) }

  let(:test_person) { create_person(30) }

  def create_person(age = 30, **attrs) = Fabricate(:person, birthday: age.years.ago, **attrs)

  def create_role(type, group, person = test_person, **attrs)
    Fabricate(type.sti_name, group: groups(group), person: person, **attrs)
  end

  def mitglied = Group::SektionsMitglieder::Mitglied

  def mitglied_zusatzsektion = Group::SektionsMitglieder::MitgliedZusatzsektion

  context "all filters false" do
    let(:filter_args) { {stammsektion: false, zusatzsektion: false} }

    it "does not filter" do
      expect(entries.size).to eq(Person.count)
    end
  end

  context "with group_id in root layer" do
    let(:group_id) { groups(:abo_die_alpen).layer_group_id }

    context "arg only stammsektion" do
      let(:filter_args) { {stammsektion: true, zusatzsektion: false, group_id:} }

      it "includes member in a sektion" do
        create_role(mitglied, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "includes member in a ortsgruppe" do
        create_role(mitglied, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
        expect(entries).to include(test_person)
      end

      it "excludes person with non-member role" do
        create_role(Group::SektionsMitglieder::Schreibrecht, :bluemlisalp_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "includes adult member" do
        person = create_person(30)
        role = create_role(mitglied, :bluemlisalp_mitglieder, person: person)
        expect(role.beitragskategorie).to eq "adult"
        expect(entries).to include(person)
      end

      it "includes youth member" do
        person = create_person(15)
        role = create_role(mitglied, :bluemlisalp_mitglieder, person: person)
        expect(role.beitragskategorie).to eq "youth"
        expect(entries).to include(person)
      end

      it "includes main person family member" do
        person = create_person(30, sac_family_main_person: true)
        role = create_role(mitglied, :bluemlisalp_mitglieder,
          person: person,
          beitragskategorie: "family")
        expect(role.beitragskategorie).to eq "family"
        expect(entries).to include(person)
      end

      it "excludes non-main person family member" do
        person = create_person(30, sac_family_main_person: true) # create as main person first
        role = create_role(mitglied, :bluemlisalp_mitglieder,
          person: person,
          beitragskategorie: "family")
        person.update!(sac_family_main_person: false) # change to non-main person
        expect(role.beitragskategorie).to eq "family"
        expect(entries).not_to include(person)
      end
    end

    context "arg only zusatzsektion" do
      let(:filter_args) { {stammsektion: false, zusatzsektion: true, group_id:} }

      it "includes zusatzsektion member" do
        create_role(mitglied, :matterhorn_mitglieder)
        create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "excludes member without zusatzsektion" do
        create_role(mitglied, :bluemlisalp_mitglieder)
        expect(entries).not_to include(test_person)
      end
    end

    context "arg both stammsektion and zusatzsektion" do
      let(:filter_args) { {stammsektion: true, zusatzsektion: true, group_id:} }

      it "includes member without zusatzsektion" do
        create_role(mitglied, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "includes zusatzsektion member" do
        create_role(mitglied, :matterhorn_mitglieder)
        create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end
    end
  end

  context "with group_id in sublayer" do
    let(:group_id) { groups(:bluemlisalp).id }

    context "arg only stammsektion" do
      let(:filter_args) { {stammsektion: true, zusatzsektion: false, group_id:} }

      it "includes member of layer" do
        create_role(mitglied, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "excludes member of another layer" do
        create_role(mitglied, :matterhorn_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "excludes member of sublayer" do
        create_role(mitglied, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "excludes zusatzsektion member of layer" do
        create_role(mitglied, :matterhorn_mitglieder)
        create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "includes adult member of layer" do
        person = create_person(30)
        role = create_role(mitglied, :bluemlisalp_mitglieder, person: person)
        expect(role.beitragskategorie).to eq "adult"
        expect(entries).to include(person)
      end

      it "includes youth member of layer" do
        person = create_person(15)
        role = create_role(mitglied, :bluemlisalp_mitglieder, person: person)
        expect(role.beitragskategorie).to eq "youth"
        expect(entries).to include(person)
      end

      it "includes main person family member of layer" do
        person = create_person(30, sac_family_main_person: true)
        role = create_role(mitglied, :bluemlisalp_mitglieder,
          person: person,
          beitragskategorie: "family")
        expect(role.beitragskategorie).to eq "family"
        expect(entries).to include(person)
      end

      it "excludes non-main person family member of layer" do
        person = create_person(30, sac_family_main_person: true) # create as main person first
        role = create_role(mitglied, :bluemlisalp_mitglieder,
          person: person,
          beitragskategorie: "family")
        person.update!(sac_family_main_person: false) # change to non-main person
        expect(role.beitragskategorie).to eq "family"
        expect(entries).not_to include(person)
      end
    end

    context "with only zusatzsektion" do
      let(:filter_args) { {stammsektion: false, zusatzsektion: true, group_id:} }

      it "includes zusatzsektion member of layer" do
        create_role(mitglied, :matterhorn_mitglieder)
        create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "excludes zusatsektion member of other layer" do
        create_role(mitglied, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
        create_role(mitglied_zusatzsektion, :matterhorn_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "excludes zusatzsektion member of sublayer" do
        create_role(mitglied, :matterhorn_mitglieder)
        create_role(mitglied_zusatzsektion, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "excludes member of layer" do
        create_role(mitglied, :bluemlisalp_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "includes adult zusatzsektion member of layer" do
        person = create_person(30)
        create_role(mitglied, :matterhorn_mitglieder, person: person)
        role = create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder, person: person)
        expect(role.beitragskategorie).to eq "adult"
        expect(entries).to include(person)
      end

      it "includes youth zusatzsektion member of layer" do
        person = create_person(15)
        create_role(mitglied, :matterhorn_mitglieder, person: person)
        role = create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder, person: person)
        expect(role.beitragskategorie).to eq "youth"
        expect(entries).to include(person)
      end

      it "includes main person family zusatzsektion member of layer" do
        person = create_person(30, sac_family_main_person: true)
        create_role(mitglied, :matterhorn_mitglieder, person: person)
        role = create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder,
          person: person,
          beitragskategorie: "family")
        expect(role.beitragskategorie).to eq "family"
        expect(entries).to include(person)
      end

      it "excludes non-main person family zusatzsektion member of layer" do
        person = create_person(30, sac_family_main_person: true) # create as main person first
        create_role(mitglied, :matterhorn_mitglieder, person: person)
        role = create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder,
          person: person,
          beitragskategorie: "family")
        person.update!(sac_family_main_person: false) # change to non-main person
        expect(role.beitragskategorie).to eq "family"
        expect(entries).not_to include(person)
      end
    end

    context "with both filters" do
      let(:filter_args) { {stammsektion: true, zusatzsektion: true, group_id:} }

      it "includes member of layer" do
        create_role(mitglied, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "includes zusatzsektion member of layer" do
        create_role(mitglied, :matterhorn_mitglieder)
        create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "excludes member of another layer" do
        create_role(mitglied, :matterhorn_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "excludes zusatzsektion member of another layer" do
        create_role(mitglied, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
        create_role(mitglied_zusatzsektion, :matterhorn_mitglieder)
        expect(entries).not_to include(test_person)
      end
    end

    context "with deep" do
      let(:filter_args) { {deep: true, stammsektion: true, zusatzsektion: true, group_id:} }

      it "includes member of layer" do
        create_role(mitglied, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "includes zusatzsektion member of layer" do
        create_role(mitglied, :matterhorn_mitglieder)
        create_role(mitglied_zusatzsektion, :bluemlisalp_mitglieder)
        expect(entries).to include(test_person)
      end

      it "includes member of sublayer" do
        create_role(mitglied, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
        expect(entries).to include(test_person)
      end

      it "excludes member of sibling layer" do
        create_role(mitglied, :matterhorn_mitglieder)
        expect(entries).not_to include(test_person)
      end

      it "includes member of sibling layer with zusatzsektion in sublayer" do
        create_role(mitglied, :matterhorn_mitglieder)
        create_role(mitglied_zusatzsektion, :bluemlisalp_ortsgruppe_ausserberg_mitglieder)
        expect(entries).to include(test_person)
      end

      it "excludes non-main person family member" do
        person = create_person(30, sac_family_main_person: true) # create as main person first
        role = create_role(mitglied, :bluemlisalp_mitglieder,
          person: person,
          beitragskategorie: "family")
        person.update!(sac_family_main_person: false) # change to non-main person
        expect(role.beitragskategorie).to eq "family"
        expect(entries).not_to include(person)
      end
    end
  end
end
