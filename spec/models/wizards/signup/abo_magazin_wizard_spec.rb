# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Signup::AboMagazinWizard do
  let(:group) do
    Fabricate.build(Group::AboMagazin.sti_name, parent: groups(:abo_magazine)).tap do |group|
      group.self_registration_role_type = Group::AboMagazin::Abonnent.sti_name
    end
  end

  subject(:wizard) { build(required_attrs) }

  def build(params = required_attrs)
    described_class.new(group: group, current_step: @current_step.to_i, **params)
  end

  let(:required_attrs) {
    {
      main_email_field: {
        email: "max.muster@example.com"
      },
      person_fields: {
        gender: "m",
        first_name: "Max",
        last_name: "Muster",
        address_care_of: "c/o Musterleute",
        street: "Musterplatz",
        housenumber: "42",
        postbox: "Postfach 23",
        town: "Zurich",
        zip_code: "8000",
        birthday: "1.1.2000",
        country: "CH",
        phone_number: "+41 79 123 45 67"
      },
      summary: {
        agb: true,
        data_protection: true
      }
    }
  }

  it "required attrs populate valid wizard" do
    expect(wizard).to be_valid
  end

  describe "validates steps" do
    it "is invalid when email is blank" do
      required_attrs[:main_email_field][:email] = ""
      expect(wizard).not_to be_valid

      expect(wizard.errors).to be_empty
      expect(wizard.main_email_field).not_to be_valid
      expect(wizard.main_email_field.errors.full_messages).to eq ["E-Mail muss ausgefüllt werden"]
    end

    context "person_fields" do
      before { @current_step = 1 }

      it "is invalid if first_name is blank" do
        required_attrs[:person_fields][:first_name] = nil
        expect(wizard).not_to be_valid
        expect(wizard.person_fields.errors.full_messages).to eq ["Vorname muss ausgefüllt werden"]
      end

      it "is valid if less than 18 years old" do
        required_attrs[:person_fields][:birthday] = 10.years.ago.to_date
        expect(wizard).to be_valid
      end

      it "is invalid if birthday is in the future" do
        required_attrs[:person_fields][:birthday] = 1.day.from_now.to_date
        expect(wizard).not_to be_valid
        expect(wizard.person_fields.errors.full_messages).to eq ["Person muss 0 Jahre oder älter sein"]
      end
    end

    context "issue_from_field" do
      before { @current_step = 2 }

      it "is invalid agreements are not checked" do
        required_attrs[:summary][:agb] = "0"
        required_attrs[:summary][:data_protection] = "0"
        expect(wizard).not_to be_valid
        expect(wizard.summary.errors.full_messages).to eq ["Agb muss akzeptiert werden", "Datenschutzerklärung muss akzeptiert werden"]
      end
    end
  end

  describe "saving" do
    let(:max) { Person.find_by(email: "max.muster@example.com") }

    before {
      group.save!
      @current_step = 1
    }

    it "creates single person" do
      expect(wizard).to be_valid
      expect { wizard.save! }.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
      expect(max.roles.last.type).to eq Group::AboMagazin::Abonnent.sti_name
      expect(max.roles.last.end_on).to eq Time.zone.now.end_of_year.to_date
      expect(max.privacy_policy_accepted_at).to be_nil
    end

    it "correctly translates I18N gender nil value" do
      required_attrs[:person_fields][:gender] = "_nil"
      wizard.save!
      expect(max.reload.gender).to be_nil
    end

    describe "newsletter" do
      include ActiveJob::TestHelper

      it "enqueues with newsletter" do
        required_attrs[:summary][:newsletter] = "0"
        expect do
          expect { wizard.save! }.not_to change { Subscription.count }
        end.to have_enqueued_mail(Signup::AboMagazinMailer, :confirmation)
          .with(kind_of(Person), group, false)
      end

      it "enqueues without newsletter" do
        required_attrs[:summary][:newsletter] = "1"
        expect do
          expect { wizard.save! }.to change { Subscription.count }.by(1)
        end.to have_enqueued_mail(Signup::AboMagazinMailer, :confirmation)
          .with(kind_of(Person), group, true)
      end
    end

    it "saves role for current_user when logged in" do
      allow_any_instance_of(Wizards::Signup::AboBasicLoginWizard).to receive(:current_user).and_return(people(:admin))
      expect(wizard).to be_valid
      expect { wizard.save! }.not_to change { Person.count }
      expect(people(:admin).roles.last.type).to eq Group::AboMagazin::Abonnent.sti_name
    end
  end

  describe "#calculate_costs" do
    before do
      Group.root.update!(abo_alpen_fee: 60, abo_alpen_postage_abroad: 16)
    end

    it "calculates costs for swiss people" do
      expect(wizard.calculated_costs).to eq(60)
    end

    it "calculates costs for people abroad" do
      required_attrs[:person_fields][:country] = "DE"
      expect(wizard.calculated_costs).to eq(76)
    end
  end

  describe "steps" do
    it "starts at main email field step when not logged in" do
      expect(wizard.step_at(0)).to be_instance_of(Wizards::Steps::Signup::MainEmailField)
      expect(wizard.step_at(1)).to be_instance_of(Wizards::Steps::Signup::AboMagazin::PersonFields)
      expect(wizard.step_at(2)).to be_instance_of(Wizards::Steps::Signup::AboMagazin::Summary)
    end

    it "starts at person fields step when logged in" do
      allow_any_instance_of(Wizards::Signup::AboBasicLoginWizard).to receive(:current_user).and_return(people(:admin))
      expect(wizard.step_at(0)).to be_instance_of(Wizards::Steps::Signup::AboMagazin::PersonFields)
      expect(wizard.step_at(1)).to be_instance_of(Wizards::Steps::Signup::AboMagazin::Summary)
    end
  end

  describe "#member_or_applied?" do
    let(:person) { people(:mitglied) }
    let(:group) { groups(:abo_die_alpen) }

    before do
      allow_any_instance_of(Wizards::Signup::AboBasicLoginWizard).to receive(:current_user).and_return(person)
    end

    it "returns true when user has abonnent role" do
      Group::AboMagazin::Abonnent.create!(person:, group:)
      expect(wizard.member_or_applied?).to be_truthy
    end

    it "returns true when user has neuanmeldung role" do
      Group::AboMagazin::Neuanmeldung.create!(person:, group:)
      expect(wizard.member_or_applied?).to be_truthy
    end

    it "returns true when user has gratis abonnent role" do
      Group::AboMagazin::Gratisabonnent.create!(person:, group:)
      expect(wizard.member_or_applied?).to be_truthy
    end

    it "returns false if user does not have role" do
      expect(wizard.member_or_applied?).to be_falsy
    end
  end
end
