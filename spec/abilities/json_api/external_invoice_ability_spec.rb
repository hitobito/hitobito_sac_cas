# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"
describe JsonApi::ExternalInvoiceAbility do
  let!(:invoice) { Fabricate(:external_invoice, link: groups(:bluemlisalp), person: people(:mitglied)) }
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

  context "index" do
    def accessible_by(user)
      ExternalInvoice.accessible_by(described_class.new(user))
    end

    it "is permitted as admin" do
      expect(accessible_by(admin)).to eq [invoice]
    end

    it "is not permitted as andere" do
      expect(accessible_by(andere)).to be_empty
    end

    it "is not permitted as mitglied" do
      expect(accessible_by(mitglied)).to be_empty
    end

    it "is not permitted as mitgliederverwaltung sektion" do
      expect(accessible_by(mitgliederverwaltung_sektion)).to be_empty
    end
  end
end
