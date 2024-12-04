# frozen_string_literal: trueV

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

describe Memberships::TerminateSacMembership do
  let(:reason) { termination_reasons(:moved) }
  let(:person) { role.person }
  let(:role) { roles(:mitglied) }

  let(:params) { {terminate_on: Time.zone.yesterday, termination_reason_id: reason.id} }

  subject(:termination) { described_class.new(role, params.delete(:terminate_on), **params) }

  describe "exceptions" do
    it "raises when role is not a mitglied role" do
      expect do
        described_class.new(roles(:mitglied_zweitsektion), Time.zone.yesterday)
      end.to raise_error("not a member")
    end

    it "raises when role is already terminated" do
      role.update_columns(terminated: true)
      expect do
        described_class.new(role, Time.zone.yesterday)
      end.to raise_error("already terminated")
    end

    it "does not raise when role is already terminated but backoffice is true" do
      role.update_columns(terminated: true)
      expect do
        described_class.new(role, Time.zone.yesterday, backoffice: true)
      end.not_to raise_error
    end

    it "raises when role is already ended" do
      role.update_columns(end_on: Date.current.yesterday)
      expect do
        described_class.new(role, Time.zone.yesterday)
      end.to raise_error("already deleted")
    end

    it "raises if not main family person" do
      expect do
        described_class.new(roles(:familienmitglied2), Time.zone.yesterday)
      end.to raise_error("not family main person")
    end
  end

  describe "validations" do
    it "is valid with defined params" do
      expect(termination).to be_valid
    end

    it "is not valid without termination_reason_id" do
      params[:termination_reason_id] = nil
      expect(termination).not_to be_valid
      expect(termination).to have(1).error_on(:termination_reason_id)
    end

    describe "terminate_on" do
      it "accepts end of year" do
        params[:terminate_on] = Time.zone.now.end_of_year.to_date
        expect(termination).to be_valid
      end

      it "rejects tomorrow or today" do
        params[:terminate_on] = Time.zone.tomorrow
        expect(termination).not_to be_valid
        expect(termination).to have(1).error_on(:terminate_on)
      end
    end

    context "family" do
      let(:role) { roles(:familienmitglied) }

      it "is valid with defined params" do
        expect(termination).to be_valid
      end
    end
  end

  describe "save" do
    it "terminates mitglied and zusatzsektion role and resets primary group" do
      expect do
        expect(termination.save!).to eq true
      end.to not_change { person.roles.with_inactive.count }
        .and change { person.roles.count }.by(-2)
      expect(person.reload.primary_group).to be_nil
    end

    it "destroys future roles" do
      future_stammsektion = role.dup.tap do |r|
        r.assign_attributes(start_on: role.end_on + 1, end_on: role.end_on + 1.year)
        r.save!
      end
      future_beguenstigt = future_stammsektion
        .dup
        .becomes(Group::SektionsMitglieder::Beguenstigt)
        .tap do |r|
        r.assign_attributes(type: Group::SektionsMitglieder::Beguenstigt.sti_name)
        r.save!
      end

      termination.save!

      expect(Role.with_inactive.where(id: future_stammsektion.id)).not_to exist
      expect(Role.with_inactive.where(id: future_beguenstigt.id)).not_to exist
    end

    it "does not touch ended roles" do
      ended_stammsektion = role.dup.tap do |r|
        r.assign_attributes(end_on: role.start_on - 1, start_on: role.start_on - 1.year)
        r.save!
      end
      ended_beguenstigt = ended_stammsektion
        .dup
        .becomes(Group::SektionsMitglieder::Beguenstigt)
        .tap do |r|
        r.assign_attributes(type: Group::SektionsMitglieder::Beguenstigt.sti_name)
        r.save!
      end

      termination.save!

      expect { ended_stammsektion.reload }
        .to not_change { ended_stammsektion.end_on }
        .and not_change { ended_beguenstigt.reload.end_on }
    end

    context "termination at the end of the year" do
      let(:end_of_year) { Time.zone.now.end_of_year.to_date }
      let(:mitglied_zweitsektion) { roles(:mitglied_zweitsektion) }

      before { params[:terminate_on] = end_of_year }

      it "does not adjust delete_on if already schedule to delete earlier" do
        Role.where(person: person).update_all(end_on: "2015-12-31")
        expect do
          expect(termination.save!).to eq true
        end.not_to(change { person.roles.count })
        expect(role.reload.end_on).to eq Date.new(2015, 12, 31)
        expect(mitglied_zweitsektion.reload.end_on).to eq Date.new(2015, 12, 31)
      end

      it "does adjust end_on if already scheduled to end later" do
        role.update!(end_on: end_of_year + 1.day)
        expect do
          expect(termination.save!).to eq true
        end
          .to not_change { person.roles.count }
          .and change { role.reload.end_on }.to(end_of_year)
      end

      it "does adjust end_on if not scheduled" do
        Role.update_all(end_on: nil)
        expect do
          expect(termination.save!).to eq true
        end.not_to(change { person.roles.count })
        expect(role.reload.end_on).to eq end_of_year
        expect(mitglied_zweitsektion.reload.end_on).to eq end_of_year
      end

      it "does update end_on when backoffice" do
        termination.save!
        expect(role.reload.terminated).to be_truthy
        expect(role.reload.end_on).to eq(end_of_year)
        described_class.new(role, Time.zone.yesterday, backoffice: true, termination_reason_id: reason.id).save!
        expect(role.reload.end_on).to eq(Time.zone.yesterday)
      end
    end

    describe "person" do
      let(:root) { groups(:root) }
      let(:mailing_list) { mailing_lists(:newsletter) }

      it "updates termination_reason" do
        expect do
          expect(termination.save!).to eq true
        end.to change { role.reload.termination_reason }.from(nil).to(reason)
      end

      describe "data_retention" do
        let(:abonnenten) { groups(:abos) }
        let!(:basic) do
          Fabricate(:group, type: Group::AboBasicLogin.sti_name, parent: abonnenten)
        end
        let(:basic_login) { basic.roles.find_by(person: person) }

        before { params[:data_retention_consent] = true }

        it "updates data_retention_consent flag and creates future basic login role" do
          expect do
            expect(termination.save!).to eq true
          end.to change { person.reload.data_retention_consent }.from(false).to(true)
          expect(basic_login).to be_a(Group::AboBasicLogin::BasicLogin)
          expect(basic_login.start_on).to eq Date.current
        end

        it "only updates consent when group is missing" do
          basic.destroy
          expect do
            expect(termination.save!).to eq true
          end.to change { person.reload.data_retention_consent }.from(false).to(true)
        end
      end

      describe "subscriptions" do
        it "destroys existing subscriptions" do
          Fabricate(:subscription, subscriber: person, mailing_list: mailing_list)
          expect do
            expect(termination.save!).to eq true
          end.to change { person.subscriptions.count }.by(-1)
        end

        describe "root group newsletter" do
          before { root.update!(sac_newsletter_mailing_list_id: mailing_list.id) }

          it "noops when param is not set" do
            expect do
              expect(termination.save!).to eq true
            end.not_to(change { person.subscriptions.count })
            expect(mailing_list.subscribed?(person)).to be false
          end

          it "creates newsletter subscription" do
            params[:subscribe_newsletter] = true
            expect do
              expect(termination.save!).to eq true
            end.to change { mailing_list.subscriptions.count }.by(1)
            expect(mailing_list.subscribed?(person)).to be true
          end

          it "does not fail on existing subscription" do
            params[:subscribe_newsletter] = true
            Person::Subscriptions.new(person).subscribe(mailing_list)
            expect(mailing_list.subscribed?(person)).to be true
            expect do
              expect(termination.save!).to eq true
            end.not_to change { mailing_list.subscriptions.count }

            expect(mailing_list.subscribed?(person)).to be true
          end
        end

        describe "root group fundraising" do
          before { root.update!(sac_fundraising_mailing_list_id: mailing_list.id) }

          it "noops when param is not set" do
            expect do
              expect(termination.save!).to eq true
            end.not_to(change { person.subscriptions.count })
          end

          it "creates fundraising subscription" do
            params[:subscribe_fundraising_list] = true
            expect do
              expect(termination.save!).to eq true
            end.to change { mailing_list.subscriptions.count }.by(1)
          end
        end
      end

      describe "external invoices" do
        it "cancels open membership invoices" do
          invoice = person.external_invoices.create!(type: ExternalInvoice::SacMembership.sti_name, state: "open", year: 2022) # matching
          other_status = person.external_invoices.create!(type: ExternalInvoice::SacMembership.sti_name, state: "payed", year: 2020) # other status
          other_type = person.external_invoices.create!(type: ExternalInvoice.sti_name, state: "open", year: 2020) # other type

          expect do
            expect(termination.save!).to eq true
          end.to change { Delayed::Job.count }.by(1)

          expect(invoice.reload).to be_cancelled
          expect(other_status.reload).to be_payed
          expect(other_type.reload).to be_open
        end
      end

      describe "other relevant roles" do
        def create_tourenleiter
          Fabricate(:qualification, person: person,
            qualification_kind: qualification_kinds(:ski_leader))
          Fabricate(
            Group::SektionsTourenUndKurse::Tourenleiter.sti_name,
            person: person,
            group: groups(:matterhorn_touren_und_kurse)
          )
        end

        ## NOTE should these validate??
        def create_future_tourenleiter
          Fabricate(:qualification, person: person,
            qualification_kind: qualification_kinds(:ski_leader))
          Fabricate(
            Group::SektionsTourenUndKurse::Tourenleiter.sti_name,
            person: person,
            group: groups(:matterhorn_touren_und_kurse),
            start_on: Date.current.tomorrow
          )
        end

        it "has expected relevant roles" do
          expect(described_class::RELEVANT_ROLES).to eq [
            Group::SektionsMitglieder::Mitglied,
            Group::SektionsMitglieder::MitgliedZusatzsektion,
            Group::SektionsMitglieder::Beguenstigt,
            Group::Ehrenmitglieder::Ehrenmitglied,

            Group::SektionsNeuanmeldungenNv::Neuanmeldung,
            Group::SektionsNeuanmeldungenNv::NeuanmeldungZusatzsektion,
            Group::SektionsNeuanmeldungenSektion::Neuanmeldung,
            Group::SektionsNeuanmeldungenSektion::NeuanmeldungZusatzsektion,

            Group::SektionsTourenUndKurse::Tourenleiter,
            Group::SektionsTourenUndKurse::TourenleiterOhneQualifikation,

            Group::ExterneKontakte::Kontakt
          ]
        end

        it "terminates tourenleiter role" do
          create_tourenleiter
          expect do
            expect(termination.save!).to eq true
          end
            .to change { person.roles.count }.by(-3)
            .and not_change { person.roles.with_inactive.count }
        end

        it "deletes future tourenleiter role" do
          # future role should get deleted, current roles schould get ended
          create_future_tourenleiter
          expect do
            expect(termination.save!).to eq true
          end
            # counts current roles, should get ended. does not count future role
            .to change { person.roles.count }.by(-2)
            # counts all roles including future and ended. future role should get deleted
            .and change { person.roles.with_inactive.count }.by(-1)
        end
      end
    end

    context "family" do
      let(:role) { roles(:familienmitglied) }

      it "terminates all family roles" do
        expect do
          expect(termination).to be_valid
          expect(termination.save!).to eq true
        end.to change { person.roles.count }.by(-2)
          .and change { Role.count }.by(-6)
      end
    end
  end
end
