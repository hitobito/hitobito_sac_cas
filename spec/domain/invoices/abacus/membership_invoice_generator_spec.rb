# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::Abacus::MembershipInvoiceGenerator do
  let(:sac) { Group.root }
  let(:date) { Date.new(2023, 1, 1) }
  let(:person_id) { people(:mitglied).id }
  let(:role) { roles(:mitglied) }
  let(:section) { groups(:bluemlisalp) }
  let(:person) { Person.with_membership_years("people.*", date).find_by(id: person_id) }
  let(:abacus_client) { instance_double(Invoices::Abacus::Client) }

  subject { described_class.new(person, date: date, client: abacus_client) }

  before do
    SacMembershipConfig.update_all(valid_from: 2020)
    SacSectionMembershipConfig.update_all(valid_from: 2020)
    Role.update_all(delete_on: date.end_of_year)
    person.update!(zip_code: 3600, town: "Thun")
  end

  it "fails if person is invalid" do
    person.update!(zip_code: nil, town: nil)
    subject.generate
    expect(subject.errors).to eq({town: :blank, zip_code: :blank})
  end

  it "creates an invoice for membership" do
    expect(abacus_client).to receive(:create).with(:subject, Hash).and_return({id: 7})
    expect(abacus_client).to receive(:create).with(:address, Hash)
    expect(abacus_client).to receive(:create).with(:communication, Hash)
    expect(abacus_client).to receive(:create).with(:customer, Hash)
    data = {
      customer_id: 7,
      delivery_date: date,
      document_code_invoice: "R",
      language: "de",
      order_date: date,
      total_amount: 183.0,
      user_fields: {
        user_field1: String,
        user_field2: "hitobito",
        user_field3: true,
        user_field4: 1.0,
        user_field11: "600001;Hillary;Edmund;#{person.membership_verify_token}"
      },
      positions: [{accounts: {},
                   position_number: 1,
                   pricing: {price_after_finding: 40.0},
                   product: {description: "Beitrag Zentralverband", product_number: "42"},
                   quantity: {charged: 1, delivered: 1, ordered: 1},
                   type: "Product",
                   user_fields: {user_field1: "Beitrag Zentralverband",
                                 user_field4: "Einzelmitglied"}},
        {accounts: {},
         position_number: 2,
         pricing: {price_after_finding: 20.0},
         product: {description: "Hütten Solidaritätsbeitrag", product_number: "44"},
         quantity: {charged: 1, delivered: 1, ordered: 1},
         type: "Product",
         user_fields: {user_field1: "Beitrag Zentralverband",
                       user_field4: "Einzelmitglied"}},
        {accounts: {},
         position_number: 3,
         pricing: {price_after_finding: 25.0},
         product: {description: "Alpengebühren", product_number: "45"},
         quantity: {charged: 1, delivered: 1, ordered: 1},
         type: "Product",
         user_fields: {user_field1: "Beitrag Zentralverband",
                       user_field4: "Einzelmitglied"}},
        {accounts: {},
         position_number: 4,
         pricing: {price_after_finding: 42.0},
         product: {description: "Beitrag SAC Blüemlisalp", product_number: "98"},
         quantity: {charged: 1, delivered: 1, ordered: 1},
         type: "Product",
         user_fields: {user_field1: "Beitrag SAC Blüemlisalp",
                       user_field2: groups(:bluemlisalp).id,
                       user_field4: "Einzelmitglied"}},
        {accounts: {},
         position_number: 5,
         pricing: {price_after_finding: 56.0},
         product: {description: "Beitrag SAC Matterhorn", product_number: "98"},
         quantity: {charged: 1, delivered: 1, ordered: 1},
         type: "Product",
         user_fields: {user_field1: "Beitrag SAC Matterhorn",
                       user_field2: groups(:matterhorn).id,
                       user_field4: "Einzelmitglied"}}]
    }
    expect(abacus_client).to receive(:create).with(:sales_order, data).and_return({sales_order_id: 19})
    expect(abacus_client).to receive(:endpoint).with(:sales_order, Hash)
    expect(abacus_client).to receive(:request).with(:post, String, Hash)

    expect do
      subject.generate
      expect(subject.errors).to eq({})
    end.to change { ExternalInvoice.count }.by(1)

    expect(person.reload.abacus_subject_key).to eq(7)

    invoice = ExternalInvoice.last
    expect(invoice.abacus_sales_order_key).to eq(19)
    expect(invoice.issued_at).to eq(date)
    expect(invoice.sent_at).to eq(date)
    expect(invoice.state).to eq("open")
    expect(invoice.to_s).to eq("Mitgliedschaftsrechnung 2023")
    expect(invoice.total).to eq(183.0)
    expect(invoice.class).to eq(ExternalInvoice::SacMembership)
    expect(invoice.year).to eq(2023)
    expect(invoice.link).to eq(section)
    expect(invoice.person).to eq(person)
  end

  context "for main family person" do
    let(:person_id) { people(:familienmitglied).id }
    let(:role) { roles(:familienmitglied) }

    it "creates an invoice for family membership" do
      expect(abacus_client).to receive(:create).with(:subject, Hash).and_return({id: 7})
      expect(abacus_client).to receive(:create).with(:address, Hash)
      expect(abacus_client).to receive(:create).with(:communication, Hash)
      expect(abacus_client).to receive(:create).with(:customer, Hash)
      data = {
        customer_id: 7,
        delivery_date: date,
        document_code_invoice: "R",
        language: "de",
        order_date: date,
        total_amount: 267.0,
        user_fields: {
          user_field1: String,
          user_field2: "hitobito",
          user_field3: true,
          user_field4: 1.0,
          user_field11: "600002;Norgay;Tenzing;#{person.membership_verify_token}",
          user_field12: "600003;Norgay;Frieda;#{people(:familienmitglied2).membership_verify_token}",
          user_field13: "600004;Norgay;Nima;#{people(:familienmitglied_kind).membership_verify_token}"
        },
        positions:
          [{accounts: {},
            position_number: 1,
            pricing: {price_after_finding: 50.0},
            product: {description: "Beitrag Zentralverband", product_number: "42"},
            quantity: {charged: 1, delivered: 1, ordered: 1},
            type: "Product",
            user_fields: {user_field1: "Beitrag Zentralverband",
                          user_field4: "Familienmitglied"}},
            {accounts: {},
             position_number: 2,
             pricing: {price_after_finding: 20.0},
             product: {description: "Hütten Solidaritätsbeitrag", product_number: "44"},
             quantity: {charged: 1, delivered: 1, ordered: 1},
             type: "Product",
             user_fields: {user_field1: "Beitrag Zentralverband",
                           user_field4: "Familienmitglied"}},
            {accounts: {},
             position_number: 3,
             pricing: {price_after_finding: 25.0},
             product: {description: "Alpengebühren", product_number: "45"},
             quantity: {charged: 1, delivered: 1, ordered: 1},
             type: "Product",
             user_fields: {user_field1: "Beitrag Zentralverband",
                           user_field4: "Familienmitglied"}},
            {accounts: {},
             position_number: 4,
             pricing: {price_after_finding: 84.0},
             product: {description: "Beitrag SAC Blüemlisalp", product_number: "98"},
             quantity: {charged: 1, delivered: 1, ordered: 1},
             type: "Product",
             user_fields: {user_field1: "Beitrag SAC Blüemlisalp",
                           user_field2: groups(:bluemlisalp).id,
                           user_field4: "Familienmitglied"}},
            {accounts: {},
             position_number: 5,
             pricing: {price_after_finding: 88.0},
             product: {description: "Beitrag SAC Matterhorn", product_number: "98"},
             quantity: {charged: 1, delivered: 1, ordered: 1},
             type: "Product",
             user_fields: {user_field1: "Beitrag SAC Matterhorn",
                           user_field2: groups(:matterhorn).id,
                           user_field4: "Familienmitglied"}}]

      }
      expect(abacus_client).to receive(:create).with(:sales_order, data).and_return({sales_order_id: 19})
      expect(abacus_client).to receive(:endpoint).with(:sales_order, Hash)
      expect(abacus_client).to receive(:request).with(:post, String, Hash)

      expect do
        subject.generate
        expect(subject.errors).to eq({})
      end.to change { ExternalInvoice.count }.by(1)

      expect(person.reload.abacus_subject_key).to eq(7)

      invoice = ExternalInvoice.last
      expect(invoice.abacus_sales_order_key).to eq(19)
      expect(invoice.issued_at).to eq(date)
      expect(invoice.sent_at).to eq(date)
      expect(invoice.state).to eq("open")
      expect(invoice.to_s).to eq("Mitgliedschaftsrechnung 2023")
      expect(invoice.total).to eq(267.0)
      expect(invoice.class).to eq(ExternalInvoice::SacMembership)
      expect(invoice.year).to eq(2023)
      expect(invoice.link).to eq(section)
      expect(invoice.person).to eq(person)
    end
  end

  context "for secondary family person" do
    let(:person_id) { people(:familienmitglied_kind).id }
    let(:role) { roles(:familienmitglied_kind) }

    it "creates no invoice for family membership" do
      expect(abacus_client).not_to receive(:create)

      expect do
        expect(subject.generate).to eq(false)
        expect(subject.errors).to eq({})
      end.not_to change { ExternalInvoice.count }
    end

    it "creates invoice for additional membership" do
      groups(:bluemlisalp_ortsgruppe_ausserberg).sac_section_membership_configs.create!(
        valid_from: 2023,
        section_fee_adult: 20,
        section_fee_family: 20,
        section_fee_youth: 20,
        section_entry_fee_adult: 10,
        section_entry_fee_family: 10,
        section_entry_fee_youth: 10,
        bulletin_postage_abroad: 0,
        reduction_amount: 0
      )

      Group::SektionsMitglieder::MitgliedZusatzsektion.create!(
        person: person,
        group: groups(:bluemlisalp_ortsgruppe_ausserberg_mitglieder),
        created_at: "2022-08-01",
        beitragskategorie: :youth,
        delete_on: "2023-12-31"
      )

      expect(abacus_client).to receive(:create).with(:subject, Hash).and_return({id: 7})
      expect(abacus_client).to receive(:create).with(:address, Hash)
      expect(abacus_client).to receive(:create).with(:communication, Hash)
      expect(abacus_client).to receive(:create).with(:customer, Hash)
      data = {
        customer_id: 7,
        delivery_date: date,
        document_code_invoice: "R",
        language: "de",
        order_date: date,
        total_amount: 20.0,
        user_fields: {
          user_field1: String,
          user_field2: "hitobito",
          user_field3: true,
          user_field4: 1.0
        },
        positions: [{accounts: {},
                     position_number: 1,
                     pricing: {price_after_finding: 0.0},
                     product: {description: "Beitrag Zentralverband", product_number: "42"},
                     quantity: {charged: 1, delivered: 1, ordered: 1},
                     type: "Product",
                     user_fields: {user_field1: "Beitrag Zentralverband",
                                   user_field4: "Familienmitglied"}},
          {accounts: {},
           position_number: 2,
           pricing: {price_after_finding: 0.0},
           product: {description: "Hütten Solidaritätsbeitrag", product_number: "44"},
           quantity: {charged: 1, delivered: 1, ordered: 1},
           type: "Product",
           user_fields: {user_field1: "Beitrag Zentralverband",
                         user_field4: "Familienmitglied"}},
          {accounts: {},
           position_number: 3,
           pricing: {price_after_finding: 0.0},
           product: {description: "Alpengebühren", product_number: "45"},
           quantity: {charged: 1, delivered: 1, ordered: 1},
           type: "Product",
           user_fields: {user_field1: "Beitrag Zentralverband",
                         user_field4: "Familienmitglied"}},
          {accounts: {},
           position_number: 4,
           pricing: {price_after_finding: 0.0},
           product: {description: "Beitrag SAC Blüemlisalp", product_number: "98"},
           quantity: {charged: 1, delivered: 1, ordered: 1},
           type: "Product",
           user_fields: {user_field1: "Beitrag SAC Blüemlisalp",
                         user_field2: groups(:bluemlisalp).id,
                         user_field4: "Familienmitglied"}},
          {accounts: {},
           position_number: 5,
           pricing: {price_after_finding: 0.0},
           product: {description: "Beitrag SAC Matterhorn", product_number: "98"},
           quantity: {charged: 1, delivered: 1, ordered: 1},
           type: "Product",
           user_fields: {user_field1: "Beitrag SAC Matterhorn",
                         user_field2: groups(:matterhorn).id,
                         user_field4: "Familienmitglied"}},
          {accounts: {},
           position_number: 6,
           pricing: {price_after_finding: 20.0},
           product: {description: "Beitrag SAC Blüemlisalp Ausserberg",
                     product_number: "98"},
           quantity: {charged: 1, delivered: 1, ordered: 1},
           type: "Product",
           user_fields: {user_field1: "Beitrag SAC Blüemlisalp Ausserberg",
                         user_field2: groups(:bluemlisalp_ortsgruppe_ausserberg).id,
                         user_field4: "Jugendmitglied"}}]
      }
      expect(abacus_client).to receive(:create).with(:sales_order, data).and_return({sales_order_id: 19})
      expect(abacus_client).to receive(:endpoint).with(:sales_order, Hash)
      expect(abacus_client).to receive(:request).with(:post, String, Hash)

      expect do
        subject.generate
        expect(subject.errors).to eq({})
      end.to change { ExternalInvoice.count }.by(1)

      expect(person.reload.abacus_subject_key).to eq(7)

      invoice = ExternalInvoice.last
      expect(invoice.abacus_sales_order_key).to eq(19)
      expect(invoice.issued_at).to eq(date)
      expect(invoice.sent_at).to eq(date)
      expect(invoice.state).to eq("open")
      expect(invoice.to_s).to eq("Mitgliedschaftsrechnung 2023")
      expect(invoice.total).to eq(20.0)
      expect(invoice.class).to eq(ExternalInvoice::SacMembership)
      expect(invoice.link).to eq(section)
      expect(invoice.year).to eq(2023)
      expect(invoice.person).to eq(person)
    end
  end

  it "handles failure in abacus request" do
    ex = RestClient::Exception.new
    expect(ex).to receive(:message).and_return("Something wrong")
    expect(abacus_client).to receive(:create).with(:subject, Hash).and_return({id: 7})
    expect(abacus_client).to receive(:create).with(:address, Hash)
    expect(abacus_client).to receive(:create).with(:communication, Hash)
    expect(abacus_client).to receive(:create).with(:customer, Hash)
    expect(abacus_client).to receive(:create).with(:sales_order, Hash).and_raise(ex)

    expect do
      expect { subject.generate }.to raise_error(RestClient::Exception)
    end.to change { ExternalInvoice.count }.by(1)

    expect(person.reload.abacus_subject_key).to eq(7)

    invoice = ExternalInvoice.last
    expect(invoice.abacus_sales_order_key).to eq(nil)
    expect(invoice.state).to eq("error")
    expect(invoice.hitobito_log_entries.count).to eq(1)
    expect(invoice.hitobito_log_entries.first.message).to eq("Something wrong")
  end
end
