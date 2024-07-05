# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Invoices::Abacus::MembershipInvoice do
  let(:sac) { Group.root }
  let(:date) { Date.new(2023, 1, 1) }
  let(:context) { Invoices::SacMemberships::Context.new(date) }
  let(:person) { people(:mitglied) }
  let(:member) { Invoices::SacMemberships::Member.new(Person.with_membership_years("people.*", date).find_by(id: person.id), context) }
  let(:abacus_client) { instance_double(Invoices::Abacus::Client) }
  let(:role) { member.main_membership_role }

  subject { described_class.new(member, role, client: abacus_client) }

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
    invoice_data = {
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
      }
    }
    expect(abacus_client).to receive(:create).with(:sales_order, invoice_data).and_return({sales_order_id: 19})
    pos1_data = {
      sales_order_id: 19,
      sales_order_backlog_id: 0,
      position_number: 1,
      type: "Product",
      pricing: {price_after_finding: 40.0},
      quantity: {ordered: 1, charged: 1, delivered: 1},
      product: {description: "Beitrag Zentralverband", product_number: "42"},
      accounts: {},
      user_fields: {user_field1: "Beitrag Zentralverband", user_field4: "Einzelmitglied"}
    }
    expect(abacus_client).to receive(:create).with(:sales_order_position, pos1_data)
    expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
    expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
    pos4_data = {
      sales_order_id: 19,
      sales_order_backlog_id: 0,
      position_number: 4,
      type: "Product",
      pricing: {price_after_finding: 42.0},
      quantity: {ordered: 1, charged: 1, delivered: 1},
      product: {description: "Beitrag SAC Blüemlisalp", product_number: "98"},
      accounts: {},
      user_fields: {user_field1: "Beitrag SAC Blüemlisalp", user_field2: groups(:bluemlisalp).id, user_field4: "Einzelmitglied"}
    }
    expect(abacus_client).to receive(:create).with(:sales_order_position, pos4_data)
    expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
    expect(abacus_client).to receive(:endpoint).with(:sales_order, Hash)
    expect(abacus_client).to receive(:request).with(:post, String, Hash)

    expect do
      subject.generate
      expect(subject.errors).to eq({})
    end.to change { Invoice.count }.by(1)

    expect(person.reload.abacus_subject_key).to eq(7)

    invoice = Invoice.last
    expect(invoice.abacus_sales_order_key).to eq(19)
    expect(invoice.group).to eq(sac)
    expect(invoice.issued_at).to eq(date)
    expect(invoice.sent_at).to eq(date)
    expect(invoice.title).to eq("Mitgliedschaftsrechnung 2023")
    expect(invoice.total).to eq(183.0)
    expect(invoice.invoice_kind).to eq("membership")
    expect(invoice.sac_membership_year).to eq(2023)
    expect(invoice.recipient).to eq(person)
  end

  context "for main family person" do
    let(:person) { people(:familienmitglied) }

    it "creates an invoice for family membership" do
      expect(abacus_client).to receive(:create).with(:subject, Hash).and_return({id: 7})
      expect(abacus_client).to receive(:create).with(:address, Hash)
      expect(abacus_client).to receive(:create).with(:communication, Hash)
      expect(abacus_client).to receive(:create).with(:customer, Hash)
      invoice_data = {
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
        }
      }
      expect(abacus_client).to receive(:create).with(:sales_order, invoice_data).and_return({sales_order_id: 19})
      pos1_data = {
        sales_order_id: 19,
        sales_order_backlog_id: 0,
        position_number: 1,
        type: "Product",
        pricing: {price_after_finding: 50.0},
        quantity: {ordered: 1, charged: 1, delivered: 1},
        product: {description: "Beitrag Zentralverband", product_number: "42"},
        accounts: {},
        user_fields: {user_field1: "Beitrag Zentralverband", user_field4: "Familienmitglied"}
      }
      expect(abacus_client).to receive(:create).with(:sales_order_position, pos1_data)
      expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
      expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
      pos4_data = {
        sales_order_id: 19,
        sales_order_backlog_id: 0,
        position_number: 4,
        type: "Product",
        pricing: {price_after_finding: 84.0},
        quantity: {ordered: 1, charged: 1, delivered: 1},
        product: {description: "Beitrag SAC Blüemlisalp", product_number: "98"},
        accounts: {},
        user_fields: {user_field1: "Beitrag SAC Blüemlisalp", user_field2: groups(:bluemlisalp).id, user_field4: "Familienmitglied"}
      }
      expect(abacus_client).to receive(:create).with(:sales_order_position, pos4_data)
      expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
      expect(abacus_client).to receive(:endpoint).with(:sales_order, Hash)
      expect(abacus_client).to receive(:request).with(:post, String, Hash)

      expect do
        subject.generate
        expect(subject.errors).to eq({})
      end.to change { Invoice.count }.by(1)

      expect(person.reload.abacus_subject_key).to eq(7)

      invoice = Invoice.last
      expect(invoice.abacus_sales_order_key).to eq(19)
      expect(invoice.group).to eq(sac)
      expect(invoice.issued_at).to eq(date)
      expect(invoice.sent_at).to eq(date)
      expect(invoice.title).to eq("Mitgliedschaftsrechnung 2023")
      expect(invoice.total).to eq(267.0)
      expect(invoice.invoice_kind).to eq("membership")
      expect(invoice.sac_membership_year).to eq(2023)
      expect(invoice.recipient).to eq(person)
    end
  end

  context "for secondary family person" do
    let(:person) { people(:familienmitglied_kind) }

    it "creates an invoice for family membership" do
      expect(abacus_client).to receive(:create).with(:subject, Hash).and_return({id: 7})
      expect(abacus_client).to receive(:create).with(:address, Hash)
      expect(abacus_client).to receive(:create).with(:communication, Hash)
      expect(abacus_client).to receive(:create).with(:customer, Hash)
      invoice_data = {
        customer_id: 7,
        delivery_date: date,
        document_code_invoice: "R",
        language: "de",
        order_date: date,
        total_amount: 0.0,
        user_fields: {
          user_field1: String,
          user_field2: "hitobito",
          user_field3: true
        }
      }
      expect(abacus_client).to receive(:create).with(:sales_order, invoice_data).and_return({sales_order_id: 19})
      pos1_data = {
        sales_order_id: 19,
        sales_order_backlog_id: 0,
        position_number: 1,
        type: "Product",
        pricing: {price_after_finding: 0.0},
        quantity: {ordered: 1, charged: 1, delivered: 1},
        product: {description: "Beitrag Zentralverband", product_number: "42"},
        accounts: {},
        user_fields: {user_field1: "Beitrag Zentralverband", user_field4: "Familienmitglied"}
      }
      expect(abacus_client).to receive(:create).with(:sales_order_position, pos1_data)
      expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
      expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
      pos4_data = {
        sales_order_id: 19,
        sales_order_backlog_id: 0,
        position_number: 4,
        type: "Product",
        pricing: {price_after_finding: 0.0},
        quantity: {ordered: 1, charged: 1, delivered: 1},
        product: {description: "Beitrag SAC Blüemlisalp", product_number: "98"},
        accounts: {},
        user_fields: {user_field1: "Beitrag SAC Blüemlisalp", user_field2: groups(:bluemlisalp).id, user_field4: "Familienmitglied"}
      }
      expect(abacus_client).to receive(:create).with(:sales_order_position, pos4_data)
      expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
      expect(abacus_client).to receive(:endpoint).with(:sales_order, Hash)
      expect(abacus_client).to receive(:request).with(:post, String, Hash)

      expect do
        subject.generate
        expect(subject.errors).to eq({})
      end.to change { Invoice.count }.by(1)

      expect(person.reload.abacus_subject_key).to eq(7)

      invoice = Invoice.last
      expect(invoice.abacus_sales_order_key).to eq(19)
      expect(invoice.group).to eq(sac)
      expect(invoice.issued_at).to eq(date)
      expect(invoice.sent_at).to eq(date)
      expect(invoice.title).to eq("Mitgliedschaftsrechnung 2023")
      expect(invoice.total).to eq(0.0)
      expect(invoice.invoice_kind).to eq("membership")
      expect(invoice.sac_membership_year).to eq(2023)
      expect(invoice.recipient).to eq(person)
    end
  end

  it "handles failure in abacus request" do
    expect(abacus_client).to receive(:create).with(:subject, Hash).and_return({id: 7})
    expect(abacus_client).to receive(:create).with(:address, Hash)
    expect(abacus_client).to receive(:create).with(:communication, Hash)
    expect(abacus_client).to receive(:create).with(:customer, Hash)
    expect(abacus_client).to receive(:create).with(:sales_order, Hash).and_return({sales_order_id: 19})
    expect(abacus_client).to receive(:create).with(:sales_order_position, Hash)
    expect(abacus_client).to receive(:create).with(:sales_order_position, Hash).and_raise("Something wrong")
    expect(abacus_client).to receive(:delete).with(:sales_order, Hash)

    expect do
      expect { subject.generate }.to raise_error("Something wrong")
    end.not_to change { Invoice.count }

    expect(person.reload.abacus_subject_key).to eq(7)
  end
end
