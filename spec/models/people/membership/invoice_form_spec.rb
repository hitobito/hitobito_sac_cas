# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

require "spec_helper"

describe People::Membership::InvoiceForm do
  let(:person) { people(:mitglied) }
  let(:sektion) { groups(:bluemlisalp) }
  let(:now) { Time.zone.local(2024, 8, 24, 1) }

  subject(:form) { described_class.new(person) }

  before {
    roles(:mitglied).update!(start_on: now.beginning_of_year, end_on: now.end_of_year)
    travel_to(now)
  }

  describe "validations" do
    let(:required_attrs) {
      {
        section_id: sektion.id,
        reference_date: 10.days.ago,
        send_date: 3.days.ago,
        invoice_date: 1.day.ago,
        discount: 0
      }
    }

    before { form.attributes = required_attrs }

    it "is valid with all params set" do
      expect(form).to be_valid
    end

    describe "section_id" do
      it "is invalid if person has no membership chosen sektion" do
        form.section_id = groups(:bluemlisalp_ortsgruppe_ausserberg).id.to_s
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Mitgliedschaft ist nicht gültig"]
      end

      it "is invalid if person has no membership chosen sektion at chosen time" do
        roles(:mitglied).update!(start_on: now.beginning_of_year, end_on: now.end_of_year)
        form.reference_date = 1.year.from_now
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Mitgliedschaft ist nicht gültig"]
      end

      it "is valid if person has neuanmeldung for stammsektion in chose section" do
        person.roles.destroy_all
        Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name, person: person, group: groups(:bluemlisalp_neuanmeldungen_nv), start_on: 1.year.ago)
        form.section_id = groups(:bluemlisalp_neuanmeldungen_nv).layer_group.id.to_s
        expect(form).to be_valid
      end
    end

    describe "send_date" do
      it "is invalid when blank" do
        form.send_date = nil
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Versand- und Rechnungsdatum muss ausgefüllt werden"]
      end

      it "is invalid when short of min date" do
        form.send_date = 1.year.ago.end_of_year
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Versand- und Rechnungsdatum muss 01.01.2024 oder danach sein"]
      end

      it "is invalid when exceeds max date" do
        form.send_date = 2.years.from_now.beginning_of_year.to_date
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to match_array ["Versand- und Rechnungsdatum muss 31.12.2024 oder davor sein"]
      end
    end

    describe "invoice_date" do
      it "is invalid when blank" do
        form.invoice_date = nil
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Buchungsdatum muss ausgefüllt werden"]
      end

      it "is invalid when short of min date" do
        form.invoice_date = 1.year.ago.end_of_year
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Buchungsdatum muss 01.01.2024 oder danach sein"]
      end

      it "is invalid when exceeds max date" do
        form.invoice_date = 2.years.from_now.beginning_of_year.to_date
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to match_array ["Buchungsdatum muss 31.12.2025 oder davor sein"]
      end
    end

    describe "reference_date" do
      it "is invalid when blank" do
        form.reference_date = nil
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Stichtag muss ausgefüllt werden"]
      end

      it "is invalid when short of min date" do
        form.reference_date = 1.year.ago.end_of_year
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Stichtag muss 01.01.2024 oder danach sein"]
      end

      it "is invalid when exceeds max date" do
        form.reference_date = 2.years.from_now.beginning_of_year.to_date
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to match_array ["Stichtag muss 31.12.2025 oder davor sein"]
      end
    end

    describe "discount" do
      it "is invalid when blank" do
        form.discount = nil
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Rabatt muss ausgefüllt werden"]
      end

      it "is invalid when invalid value is used" do
        form.discount = 13
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["Rabatt ist kein gültiger Wert"]
      end

      [0, 50, 100].each do |value|
        it "is valid for #{value}" do
          form.discount = value
          expect(form).to be_valid
        end
      end
    end
  end

  describe "date ranges" do
    it "spans start of current to end of next year" do
      expect(form.min_date).to eq Date.new(2024, 1, 1)
      expect(form.max_date).to eq Date.new(2025, 12, 31)
    end

    it "uses end of this year for max_send_date" do
      expect(form.max_send_date).to eq Date.new(2024, 12, 31)
    end

    it "uses end of this year for max_send_date for people with neuanmeldung roles" do
      person.roles.destroy_all
      Fabricate(Group::SektionsNeuanmeldungenNv::Neuanmeldung.sti_name, person: person, group: groups(:bluemlisalp_neuanmeldungen_nv), start_on: 1.year.ago)
      expect(form.max_send_date).to eq Date.new(2024, 12, 31)
    end

    context "with membership for next year" do
      before { roles(:mitglied).update!(end_on: 3.years.from_now) }

      it "spans start of current to end of next year for all dates" do
        expect(form.min_date).to eq Date.new(2024, 1, 1)
        expect(form.max_date).to eq Date.new(2025, 12, 31)
        expect(form.max_send_date).to eq Date.new(2025, 12, 31)
      end
    end
  end

  describe "stammsektion" do
    it "returns sektion for stammsektion role" do
      expect(form.stammsektion).to eq groups(:bluemlisalp)
    end

    it "is nil when stammsektion role has been destroyed" do
      roles(:mitglied).destroy
      expect(form.stammsektion).to be_nil
    end
  end

  describe "zusatzsektionen" do
    it "returns sektion for zusatzsektionen role" do
      expect(form.zusatzsektionen).to eq [groups(:matterhorn)]
    end

    it "is empty when zweitsektion role has been destroyed" do
      roles(:mitglied_zweitsektion).destroy
      expect(form.zusatzsektionen).to be_empty
    end

    it "return sektion of neuanmeldung_nv zusatzsektion role" do
      roles(:mitglied_zweitsektion).destroy
      Fabricate(Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion.name,
        person: person,
        group: groups(:matterhorn_neuanmeldungen_nv),
        start_on: Date.current.beginning_of_year,
        end_on: Date.current.end_of_year).person
      expect(form.zusatzsektionen).to eq [groups(:matterhorn)]
    end

    it "is empty for neuanmeldung sektion zusatzsektion role" do
      roles(:mitglied_zweitsektion).destroy
      Fabricate(Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion.name,
        person: person,
        group: groups(:matterhorn_neuanmeldungen_sektion),
        start_on: Date.current.beginning_of_year,
        end_on: Date.current.end_of_year).person
      expect(form.zusatzsektionen).to be_empty
    end
  end
end
