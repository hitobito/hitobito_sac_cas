# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Signup::SektionOperation do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:person_attrs) {
    {
      first_name: "Max",
      last_name: "Muster",
      address_care_of: "c/o Musterleute",
      street: "Musterplatz",
      housenumber: "42",
      postbox: "Postfach 23",
      town: "Zurich",
      email: "max.muster@example.com",
      zip_code: "8000",
      birthday: "1.1.2000",
      country: "CH",
      phone_numbers_attributes: [
        {number: "0791234567", label: "Mobil"}
      ]
    }
  }

  let(:newsletter) { true }
  let(:register_on) { Time.zone.today }

  subject(:operation) { described_class.new(person_attrs: person_attrs, group:, register_on:, newsletter:) }

  describe "validations" do
    it "is valid" do
      expect(operation).to be_valid
    end

    it "validates person" do
      person_attrs[:first_name] = nil
      person_attrs[:last_name] = nil
      expect(operation).not_to be_valid
      expect(operation.errors.full_messages).to eq ["Bitte geben Sie einen Namen ein"]
    end

    it "validates role" do
      allow(group).to receive(:self_registration_role_type).and_return(nil)
      expect(operation).not_to be_valid
      expect(operation.errors.full_messages).to eq ["Rolle muss ausgefüllt werden"]
    end
  end

  it "#save! creates person and role" do
    expect { operation.save! }
      .to change { Person.count }.by(1)
      .and change { Role.count }.by(1)
      .and not_change { Subscription.count }

    max = Person.find_by(first_name: "Max")
    expect(max.first_name).to eq "Max"
    expect(max.last_name).to eq "Muster"
    expect(max.address_care_of).to eq "c/o Musterleute"
    expect(max.street).to eq "Musterplatz"
    expect(max.housenumber).to eq "42"
    expect(max.postbox).to eq "Postfach 23"
    expect(max.town).to eq "Zurich"
    expect(max.email).to eq "max.muster@example.com"
    expect(max.zip_code).to eq "8000"
    expect(max.birthday).to eq Date.new(2000, 1, 1)
    expect(max.country).to eq "CH"

    expect(max.roles.first.type).to eq "Group::SektionsNeuanmeldungenSektion::Neuanmeldung"
    expect(max.roles.first.group).to eq group
    expect(max.phone_numbers.first.label).to eq "Mobil"
    expect(max.phone_numbers.first.number).to eq "+41 79 123 45 67"
  end

  it "#save! doesnt create invoice when approval is needed" do
    expect { operation.save! }
      .to not_change { ExternalInvoice::SacMembership.count }
      .and not_change { Delayed::Job.where("handler like '%CreateInvoiceJob%'").count }
  end

  context "no approval" do
    subject(:operation) { described_class.new(person_attrs: person_attrs, group: groups(:bluemlisalp_neuanmeldungen_nv), register_on:, newsletter:) }

    # destroy sektion neuanmeldung group to trigger no approval needed case
    before { group.really_destroy! }

    context "register on after 15th of month" do
      let(:register_on) { Date.new(2024, 6, 20) }

      it "#save! creates invoice and starts job" do
        travel_to(Date.new(2024, 6, 1)) do
          expect { operation.save! }
            .to change { ExternalInvoice::SacMembership.count }.by(1)
            .and change { Delayed::Job.where("handler like '%CreateInvoiceJob%'").count }.by(1)

          invoice = ExternalInvoice::SacMembership.last
          expect(invoice.state).to eq("draft")
          expect(invoice.person_id).to eq(Person.last.id)
          expect(invoice.issued_at).to eq(Date.current)
          expect(invoice.sent_at).to eq(Date.current)
          expect(invoice.link_id).to eq(groups(:bluemlisalp_neuanmeldungen_nv).layer_group.id)
          expect(invoice.year).to eq(Date.current.year)
        end
      end
    end

    context "register on before 15th of month" do
      let(:register_on) { Date.new(2025, 6, 9) }

      it "#save! creates invoice with 15th of month before register_on" do
        expect { operation.save! }
          .to change { ExternalInvoice::SacMembership.count }.by(1)
          .and change { Delayed::Job.where("handler like '%CreateInvoiceJob%'").count }.by(1)

        invoice = ExternalInvoice::SacMembership.last
        expect(invoice.issued_at).to eq(Date.new(2025, 5, 15))
        expect(invoice.sent_at).to eq(Date.new(2025, 5, 15))
      end
    end
  end

  context "with later start date" do
    let(:register_on) { Date.new(2024, 7, 1) }

    it "#save! future role" do
      travel_to(Date.new(2024, 6, 1)) do
        expect { operation.save! }
          .to change { Person.count }.by(1)
          .and change { FutureRole.count }.by(1)
          .and not_change { Subscription.count }
      end

      max = Person.find_by(first_name: "Max")
      expect(max.roles.first.group).to eq group
      expect(max.roles.first.type).to eq "FutureRole"
      expect(max.roles.first.convert_to).to eq "Group::SektionsNeuanmeldungenSektion::Neuanmeldung"
      expect(max.roles.first.convert_on).to eq Date.new(2024, 7, 1)
    end
  end

  context "with newsletter exclusion" do
    let(:newsletter) { false }
    let(:subscription) { Person.find_by(first_name: "Max").subscriptions.first }

    it "#save! creates excluding subscription" do
      expect do
        operation.save!
      end.to change { Subscription.count }.by(1)

      expect(subscription).to be_excluded
      expect(subscription.mailing_list).to eq mailing_lists(:newsletter)
    end
  end
end
