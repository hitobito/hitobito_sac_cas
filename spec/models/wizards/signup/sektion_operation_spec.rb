# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Signup::SektionOperation do
  include ActiveJob::TestHelper

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

  subject(:operation) { described_class.new(person_attrs: person_attrs, group:, newsletter:) }

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

  describe "#save!" do
    it "creates person and role" do
      expect { operation.save! }
        .to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
        .and not_change { Subscription.count }
        .and change { Delayed::Job.count }.by(1)
        .and change { Delayed::Job.where("handler like '%Person::DuplicateLocatorJob%'").count }
        .and not_change { ExternalInvoice::SacMembership.count }

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

    describe "password reset email" do
      it "does not send if person has no email" do
        person_attrs[:email] = nil
        expect { operation.save! }.not_to change { ActionMailer::Base.deliveries.count }
      end

      it "does send email if person has an email" do
        expect { operation.save! }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(last_email.body.to_s).to include("Bitte setze ein Passwort")
      end
    end

    describe "notification email" do
      include ActiveJob::TestHelper

      it "is sent if group has email set" do
        group.update!(self_registration_notification_email: "hello@example.com")

        expect { operation.save! }.to have_enqueued_job.on_queue("mailers").with(
          "Groups::SelfRegistrationNotificationMailer", "self_registration_notification", "deliver_now",
          args: ["hello@example.com", anything]
        )
      end
    end

    context "sektion requiring approval" do
      it "does not create invoice but enqueues confirmation email" do
        expect { operation.save! }
          .to not_change { ExternalInvoice::SacMembership.count }
          .and not_change { Delayed::Job.where("handler like '%CreateInvoiceJob%'").count }
          .and have_enqueued_mail(Signup::SektionMailer, :approval_pending_confirmation).exactly(:once)
          .with(operation.send(:person), group.layer_group)
      end

      it "does not enqueue confirmation email if not main person" do
        allow_any_instance_of(Wizards::Signup::SektionOperation).to receive(:main_person?).and_return(false)
        expect { operation.save! }.not_to have_enqueued_mail(Signup::SektionMailer)
      end
    end

    context "sektion not requiring approval" do
      let(:group) { groups(:bluemlisalp_neuanmeldungen_nv) }
      let(:invoice) { ExternalInvoice::SacMembership.last }

      before { groups(:bluemlisalp_neuanmeldungen_sektion).really_destroy! }

      it "does not create invoice but enqueues job and confirmation email" do
        expect { operation.save! }
          .to change { ExternalInvoice::SacMembership.count }.by(1)
          .and change { Delayed::Job.where("handler like '%CreateInvoiceJob%'").count }.by(1)
          .and have_enqueued_mail(Signup::SektionMailer, :confirmation).exactly(:once)
          .with(operation.send(:person), group.layer_group)

        invoice = ExternalInvoice::SacMembership.last
        expect(invoice.state).to eq("draft")
        expect(invoice.person_id).to eq(Person.last.id)
        expect(invoice.issued_at).to eq(Date.current)
        expect(invoice.sent_at).to eq(Date.current)
        expect(invoice.link_id).to eq(group.layer_group.id)
        expect(invoice.year).to eq(Date.current.year)
      end

      it "#save! creates invoice and starts job" do
        travel_to(Date.new(2024, 6, 20)) do
          operation.save!
          expect(invoice.issued_at).to eq(Date.current)
          expect(invoice.sent_at).to eq(Date.current)
          expect(invoice.year).to eq(Date.current.year)
        end
      end
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
