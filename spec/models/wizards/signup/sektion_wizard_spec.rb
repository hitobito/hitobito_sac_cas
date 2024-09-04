# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Signup::SektionWizard do
  let(:group) { groups(:bluemlisalp_neuanmeldungen_sektion) }
  let(:params) { {} }

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
        street: "Musterplatz",
        housenumber: "42",
        postbox: "Postfach 23",
        town: "Zurich",
        zip_code: "8000",
        birthday: "1.1.2000",
        country: "CH",
        phone_number: "+41 79 123 45 67"
      },
      various_fields: {
        statutes: true,
        contribution_regulations: true,
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

    it "is invalid when on person_fields step and street is blank" do
      @current_step = 1
      required_attrs[:person_fields][:street] = nil
      expect(wizard).not_to be_valid
      expect(wizard.errors).to be_empty
      expect(wizard.person_fields).not_to be_valid
      expect(wizard.person_fields.errors.full_messages).to eq ["Strasse muss ausgefüllt werden"]
    end

    it "is invalid when on family_fields step and birthday is blank" do
      @current_step = 2
      required_attrs[:family_fields] = {
        members_attributes: [
          [0, {first_name: "Maxine", last_name: "Muster"}]
        ]
      }
      expect(wizard).not_to be_valid
      expect(wizard.errors).to be_empty
      expect(wizard.family_fields).not_to be_valid
      expect(wizard.family_fields.members.first.errors.full_messages).to eq [
        "Geburtstag muss ausgefüllt werden"
      ]
    end

    it "is invalid when on family_fields step and resuses main person email" do
      @current_step = 2
      required_attrs[:family_fields] = {
        members_attributes: [
          [0, {first_name: "Maxine", last_name: "Muster", birthday: "1.1.2000", email: "max.muster@example.com"}]
        ]
      }
      expect(wizard).not_to be_valid
      expect(wizard.errors).to be_empty
      expect(wizard.family_fields).not_to be_valid
      expect(wizard.family_fields.members.first.errors.full_messages).to eq ["E-Mail (optional) ist bereits vergeben. Die E-Mail muss eindeutig sein pro Person."]
    end

    it "is invalid when on family_fields step and uses existing email" do
      @current_step = 2
      required_attrs[:family_fields] = {
        members_attributes: [
          [0, {first_name: "Maxine", last_name: "Muster", birthday: "1.1.2000", email: "e.hillary@hitobito.example.com"}]
        ]
      }
      expect(wizard).not_to be_valid
      expect(wizard.errors).to be_empty
      expect(wizard.family_fields).not_to be_valid
      expect(wizard.family_fields.members.first.errors.full_messages).to eq ["E-Mail (optional) ist bereits vergeben. Die E-Mail muss eindeutig sein pro Person."]
    end

    it "is invalid when on various_fields step and data_protection is blank" do
      @current_step = 3
      required_attrs[:various_fields] = {data_protection: nil}
      expect(wizard).not_to be_valid
      expect(wizard.errors).to be_empty
      expect(wizard.various_fields).not_to be_valid
    end
  end

  describe "optional steps" do
    before { @current_step = 1 }

    it "third step defaults to family_fields" do
      expect(wizard.step_at(2)).to be_instance_of(Wizards::Steps::Signup::Sektion::FamilyFields)
      expect(wizard.step_at(3)).to be_instance_of(Wizards::Steps::Signup::Sektion::VariousFields)
    end

    it "skips family_fields when person is not old enough" do
      required_attrs[:person_fields][:birthday] = 20.years.ago.to_date
      expect(wizard.step_at(2)).to be_instance_of(Wizards::Steps::Signup::Sektion::VariousFields)
      expect(wizard.step_at(3)).to be_nil
    end
  end

  describe "saving" do
    let(:max) { Person.find_by(email: "max.muster@example.com") }
    let(:maxi) { Person.find_by(first_name: "Maxi") }
    let(:maxine) { Person.find_by(first_name: "Maxine") }

    before { @current_step = 3 }

    it "creates single person" do
      expect(wizard).to be_valid
      expect { wizard.save! }.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
      expect(max.roles.last.beitragskategorie).to eq "adult"
    end

    it "creates single person when skiping family step" do
      required_attrs[:person_fields][:birthday] = 20.years.ago.to_date
      expect(wizard).to be_valid
      expect { wizard.save! }.to change { Person.count }.by(1)
        .and change { Role.count }.by(1)
      expect(max.roles.last.beitragskategorie).to eq "youth"
    end

    it "creates multiple people and sets household key" do
      required_attrs[:family_fields] = {
        members_attributes: [
          [1, {first_name: "Maxi", last_name: "Muster", birthday: "1.1.2012"}],
          [0, {first_name: "Maxine", last_name: "Muster", birthday: "1.1.2002"}]
        ]
      }
      expect(wizard).to be_valid
      expect { wizard.save! }.to change { Person.count }.by(3)
        .and change { Role.count }.by(3)
      expect(max.roles.last.beitragskategorie).to eq "family"
      expect(max.household_key).to be_present
      expect(maxi.household_key).to eq(max.household_key)
      expect(maxine.household_key).to eq(max.household_key)
      expect(maxi.roles.last.beitragskategorie).to eq "family"
      expect(maxine.roles.last.beitragskategorie).to eq "family"
    end

    context "various fields" do
      before do
        required_attrs[:family_fields] = {
          members_attributes: [
            [1, {first_name: "Maxi", last_name: "Muster", birthday: "1.1.2012"}]
          ]
        }
      end

      it "sets self_registration_reason on all" do
        reason = Fabricate(:self_registration_reason)
        required_attrs[:various_fields][:self_registration_reason_id] = reason.id
        wizard.save!
        expect(max.self_registration_reason).to eq reason
        expect(maxi.self_registration_reason).to eq reason
      end

      it "sets privacy_policy_accepted_at on all" do
        freeze_time
        required_attrs[:various_fields][:sektion_statuten] = "1"
        wizard.save!
        expect(max.privacy_policy_accepted_at).to eq Time.zone.now
        expect(maxi.privacy_policy_accepted_at).to eq Time.zone.now
      end

      it "creates newsletter exclusion for all" do
        freeze_time
        required_attrs[:various_fields][:newsletter] = "0"
        wizard.save!
        expect(max.subscriptions).to have(1).item
        expect(maxi.subscriptions).to have(1).items
      end

      it "creates roles but no newsletter exclusions" do
        freeze_time
        required_attrs[:various_fields][:newsletter] = "1"
        expect { wizard.save! }.to change { Role.count }.by(2)
        expect(max.subscriptions).to be_empty
        expect(maxi.subscriptions).to be_empty
      end

      it "creates future roles if register_on is in the future" do
        required_attrs[:various_fields][:register_on] = "jul"
        travel_to(Time.zone.local(2023, 3, 12)) do
          wizard.save!
        end
        expect(max.roles.last).to be_kind_of(FutureRole)
        expect(maxi.roles.last).to be_kind_of(FutureRole)
      end
    end
  end
end
