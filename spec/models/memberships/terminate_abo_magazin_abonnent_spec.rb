# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::TerminateAboMagazinAbonnent do
  let(:role) { roles(:abonnent_alpen) }
  let(:person) { people(:abonnent) }
  let(:today) { Date.new(2025, 12, 1) }
  let(:valid_attrs) { {entry_fee_consent: true, online_articles_consent: true, terminate_on: Date.new(2025, 12, 31)} }

  subject(:model) { described_class.new(role, valid_attrs) }

  around { |ex|
    travel_to(today) {
      role.update(end_on: Time.zone.now.end_of_year)
      ex.run
    }
  }

  describe "::validations" do
    it "is valid with valid attrs" do
      expect(model).to be_valid
    end

    it "requires entry_fee_consent to be accepted" do
      model.entry_fee_consent = false
      expect(model).to be_invalid
    end

    it "requires online_articles_consent to be accepted" do
      model.online_articles_consent = false
      expect(model).to be_invalid
    end

    describe "terminate_on" do
      it "accepts yesterday for terminate_on" do
        model.terminate_on = today - 1.day
        expect(model).to be_valid
      end

      it "accepts end of year" do
        model.terminate_on = today.end_of_year
        expect(model).to be_valid
      end

      it "refutes blank value" do
        model.terminate_on = ""
        expect(model).to be_invalid
        expect(model.errors.full_messages).to eq ["Beenden ab ist kein gültiger Wert"]
      end

      it "refutes any other day" do
        model.terminate_on = 5.days.ago
        expect(model).to be_invalid
        expect(model.errors.full_messages).to eq ["Beenden ab ist kein gültiger Wert"]
        model.terminate_on = 5.days.from_now
        expect(model).to be_invalid
        expect(model.errors.full_messages).to eq ["Beenden ab ist kein gültiger Wert"]
      end
    end
  end

  it "builds labels and values for terminate_on from role" do
    role.end_on = Date.new(2025, 12, 12)
    expect(model.terminate_on_options).to eq [
      ["Sofort", Date.new(2025, 11, 30)],
      ["Auf 12.12.2025", Date.new(2025, 12, 12)]
    ]
  end

  it "is submit_enabled dependend on required acceptance attrs" do
    expect(model).to be_submit_enabled
    model.entry_fee_consent = false
    expect(model).not_to be_submit_enabled
    model.entry_fee_consent = true
    model.online_articles_consent = false
    expect(model).not_to be_submit_enabled
  end

  describe "#save" do
    def create_basic_login_role
      person.roles.create!(
        type: Group::AboBasicLogin::BasicLogin.sti_name,
        group: Group::AboBasicLogin.first,
        start_on: 1.year.ago
      )
    end

    it "validates before persisting" do
      model.terminate_on = ""
      expect(model.save).to eq false
      expect(model.errors.full_messages).to eq ["Beenden ab ist kein gültiger Wert"]
    end

    describe "terminating role" do
      it "terminates immediately" do
        model.terminate_on = today - 1.day
        expect do
          expect(model.save).to eq true
        end.to change { person.roles.count }.by(-1)
        expect(role.reload).to be_terminated
        expect(role.end_on).to eq today - 1.day
      end

      it "terminates at end of role duration" do
        model.terminate_on = today.end_of_year
        expect do
          expect(model.save).to eq true
        end.not_to change { person.roles.count }
        expect(role.reload).to be_terminated
        expect(role.end_on).to eq today.end_of_year
      end
    end

    context "data retention consent" do
      before { model.terminate_on = today - 1.day }

      context "giving consent" do
        before { model.data_retention_consent = true }

        it "changes data retention consent field" do
          expect do
            expect(model.save).to eq true
          end.to change { person.reload.data_retention_consent }.from(false).to(true)
        end

        it "creates missing basic login role" do
          expect(model.save).to eq true
          basic_login_role = person.roles.find_by(type: Group::AboBasicLogin::BasicLogin.sti_name)
          expect(basic_login_role.start_on).to eq today
        end

        it "does not modify existing basic login role" do
          basic_login_role = create_basic_login_role
          expect do
            expect(model.save).to eq true
          end.not_to change { basic_login_role.reload.attributes }
        end
      end

      context "denying consent" do
        before { model.data_retention_consent = false }

        it "does not create missing basic login role" do
          expect do
            expect(model.save).to eq true
          end.not_to change { person.reload.data_retention_consent }
          expect(model.save).to eq true
          expect(role.reload.end_on).to eq today - 1.day
          expect(person.roles).to be_empty
        end

        it "terminating now deletes existing basic login role" do
          create_basic_login_role

          expect(model.save).to eq true
          expect(person.reload.roles).to be_empty
        end

        it "terminating later sets end_on of existing basic login role" do
          basic_login_role = create_basic_login_role
          expect do
            model.terminate_on = role.end_on
            expect(model.save).to eq true
          end.to change { basic_login_role.reload.end_on }.from(nil).to(role.end_on)
        end
      end
    end

    describe "mailing lists" do
      let(:newsletter) { mailing_lists(:newsletter) }
      let(:fundraising) { mailing_lists(:fundraising) }

      before { model.terminate_on = today - 1.day }

      it "subscribes to newsletter" do
        model.subscribe_newsletter = true
        expect do
          expect(model.save).to eq true
        end.to change { newsletter.subscriptions.count }.by(1)
      end

      it "subscribes to fundraising" do
        fundraising.update!(subscribable_for: :anyone, subscribable_mode: :opt_out)
        model.subscribe_fundraising_list = true
        expect do
          expect(model.save).to eq true
        end.to change { fundraising.subscriptions.count }.by(1)
      end
    end

    describe "cancelling invoices" do
      before { model.terminate_on = today - 1.day }

      def create_invoice(year:, state: :open, link: groups(:abo_die_alpen), type: :abo_magazin_invoice)
        Fabricate(type, person:, link:, state:, year:)
      end

      def cancel_invoice_jobs(invoice = nil)
        Delayed::Job.where("handler like '%CancelInvoiceJob%external_invoice_id: #{invoice&.id}%'").count
      end

      it "does not cancel invoice for this year" do
        invoice = create_invoice(year: 2025)
        expect(invoice).to be_cancellable
        expect do
          expect(model.save).to eq true
        end.not_to change { person.external_invoices.cancelled.count }
      end

      it "cancels invoice for next year" do
        invoice = create_invoice(year: 2026)
        expect(invoice).to be_cancellable
        expect do
          expect(model.save).to eq true
        end.to change { person.external_invoices.cancelled.count }.by(1)
          .and change { cancel_invoice_jobs(invoice) }.by(1)
      end

      it "does not cancel other type of invoice" do
        invoice = create_invoice(year: 2026, type: :sac_membership_invoice, link: groups(:bluemlisalp_mitglieder))
        expect(invoice).to be_cancellable
        expect do
          expect(model.save).to eq true
        end.to not_change { person.external_invoices.cancelled.count }
          .and not_change { cancel_invoice_jobs }
      end
    end
  end
end
