# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

class ExternalInvoice::DummyInvoice < ExternalInvoice
end

describe Invoices::Abacus::CreateYearlyInvoicesJob do
  let(:params) { {invoice_year:, invoice_date:, send_date:, role_finish_date:} }
  let(:invoice_year) { 2024 }
  let(:invoice_date) { nil }
  let(:send_date) { nil }
  let(:role_finish_date) { nil }
  let(:subject) { described_class.new(**params) }

  describe "#enqueue!" do
    it "will create a job and raise if there is already one running" do
      expect { subject.enqueue! }.to change(Delayed::Job, :count).by(1)
      expect { subject.enqueue! }.to raise_error("There is already a job running")
    end
  end

  def create_person(role_created_at: Date.new(invoice_year, 1, 1), params: {})
    group = groups(:bluemlisalp_mitglieder)
    person = Fabricate.create(:person_with_address, **params)
    Fabricate.create(Group::SektionsMitglieder::Mitglied.sti_name, created_at: role_created_at, group:, person:)
    person
  end

  describe "#active_members" do
    context "without any people that have an abacus_subject_key" do
      it "returns an empty array" do
        expect(subject.active_members).to eq []
      end
    end

    context "with a wild mix of people" do
      before do
        # People that shouldn't show up
        people(:familienmitglied2).update!(abacus_subject_key: "125", data_quality: :error)
        create_person(role_created_at: Date.new(invoice_year, 8, 16), params: {abacus_subject_key: "126"})
        person = create_person(params: {abacus_subject_key: "127"})
        person.external_invoices.create!(type: ExternalInvoice::SacMembership, year: invoice_year)

        # People that should show up
        people(:mitglied).update!(abacus_subject_key: "123")
        people(:familienmitglied).update!(abacus_subject_key: "124")
        valid_person = create_person(params: {abacus_subject_key: "128"})
        valid_person.external_invoices.create!(type: ExternalInvoice::DummyInvoice, year: invoice_year)
        @expected_people = [
          people(:mitglied),
          people(:familienmitglied),
          valid_person,
          create_person(params: {abacus_subject_key: "129"})
        ]
      end

      it "returns the correct people" do
        expect(subject.active_members).to match_array(@expected_people)
      end
    end
  end
end
