# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe ExternalInvoiceAbility do
  let(:invoice) {
    Fabricate(:external_invoice, link: groups(:bluemlisalp), person: people(:mitglied))
  }
  let(:admin) { people(:admin) }
  let(:mitglied) { people(:mitglied) }
  let(:andere) do
    Fabricate(Group::Geschaeftsstelle::Andere.sti_name.to_sym,
      group: groups(:geschaeftsstelle)).person
  end
  let(:mitgliederverwaltung_sektion) do
    Fabricate(Group::SektionsFunktionaere::Mitgliederverwaltung.sti_name.to_sym,
      group: groups(:bluemlisalp_funktionaere)).person
  end

  context "manage" do
    it "is permitted as admin" do
      expect(Ability.new(admin)).to be_able_to(:manage, invoice)
    end

    it "is not permitted as andere" do
      expect(Ability.new(andere)).not_to be_able_to(:manage, invoice)
    end

    it "is not permitted as mitglied" do
      expect(Ability.new(mitglied)).not_to be_able_to(:manage, invoice)
    end

    it "is not permitted as mitgliederverwaltung sektion" do
      expect(Ability.new(mitgliederverwaltung_sektion)).not_to be_able_to(:manage, invoice)
    end
  end
end
