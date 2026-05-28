# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe People::SacMembershipInvoice do
  let(:year) { Date.current.year }

  describe "#invoicable?" do
    it "is false for non member" do
      expect_invoicable(people(:admin), false)
    end

    it "is true for neuanmeldung" do
      person = people(:admin)
      Fabricate(::Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name,
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv),
        person: person,
        beitragskategorie: :adult)
      expect_invoicable(person, true)
    end

    it "is true for member" do
      expect_invoicable(people(:mitglied), true)
    end

    it "is true for main family person" do
      expect_invoicable(people(:familienmitglied), true)
    end

    it "is false for family child" do
      expect_invoicable(people(:familienmitglied_kind), false)
    end

    it "is true for family child with individual zusatzsektion" do
      person = people(:familienmitglied_kind)
      Fabricate(::Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.sti_name,
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_neuanmeldungen_nv),
        person: person,
        beitragskategorie: :youth)
      expect_invoicable(person, true)
    end

    it "is false for past member" do
      people(:mitglied).roles.update_all(end_on: Date.new(year - 1, 12, 31), terminated: true)
      expect_invoicable(people(:mitglied), false)
    end

    it "is true for membership ended in current year" do
      travel_to(Date.new(year, 6, 1))
      people(:mitglied).roles.update_all(end_on: Date.new(year, 3, 31), terminated: true)
      expect_invoicable(people(:mitglied), true)
    end

    def expect_invoicable(person, value)
      expect(person.sac_membership_invoice?).to eq(value)
    end
  end
end
