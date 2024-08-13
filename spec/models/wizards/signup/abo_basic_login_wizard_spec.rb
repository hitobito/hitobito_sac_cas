# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Signup::AboBasicLoginWizard do
  let(:group) do
    Fabricate.build(Group::AboBasicLogin.sti_name, parent: groups(:abonnenten)).tap do |group|
      group.self_registration_role_type = Group::AboBasicLogin::BasicLogin.sti_name
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
        first_name: "Max",
        last_name: "Muster",
        address_care_of: "c/o Musterleute",
        birthday: "1.1.2000",
        data_protection: "1",
        statutes: "1"
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

      it "is invalid agreements are not checked" do
        required_attrs[:person_fields][:statutes] = "0"
        required_attrs[:person_fields][:data_protection] = "0"
        expect(wizard).not_to be_valid
        expect(wizard.person_fields.errors.full_messages).to eq ["Statuten muss akzeptiert werden", "Datenschutzerklärung muss akzeptiert werden"]
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
      expect(max.roles.last.type).to eq Group::AboBasicLogin::BasicLogin.sti_name
      expect(max.roles.last.delete_on).to eq Time.zone.now.end_of_year.to_date
      expect(max.privacy_policy_accepted_at).to be_nil
    end

    it "creates newsletter exclusion for all" do
      required_attrs[:person_fields][:newsletter] = "0"
      wizard.save!
      expect(max.subscriptions).to have(1).item
    end
  end
end
