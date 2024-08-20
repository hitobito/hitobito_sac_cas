# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe Wizards::Steps::Signup::Sektion::FamilyFields do
  let(:wizard) { instance_double(Wizards::Signup::SektionWizard, email: "test@example.com", requires_adult_consent?: false, requires_policy_acceptance?: false) }
  subject(:form) { described_class.new(wizard) }

  let(:required_attrs) {
    {
      first_name: "Max",
      last_name: "Muster",
      birthday: "01.01.2000"
    }
  }

  it "builds member from members_attributes" do
    form.members_attributes = [
      [0, required_attrs]
    ]
    expect(form).to be_valid
    expect(form.members).to have(1).item
    expect(form.members[0].person_attributes).to eq(required_attrs.merge(birthday: Date.new(2000, 1, 1)))
  end

  describe "validations" do
    it "is valid when no attributes are set" do
      expect(form).to be_valid
    end

    context "single member" do
      it "is valid when valid attributes are set" do
        form.members_attributes = [
          [0, required_attrs]
        ]
        expect(form).to be_valid
        expect(form.members[0]).to be_valid
      end

      [:first_name, :last_name, :birthday].each do |attr|
        it "is invalid if #{attr} is missing" do
          form.members_attributes = [
            [0, required_attrs.except(attr)]
          ]
          expect(form).not_to be_valid
          expect(form.members[0]).not_to be_valid
          expect(form.members[0]).to have(1).error_on(attr)
        end
      end
    end

    context "multiple members" do
      before { travel_to(Date.new(2024, 7, 30)) }

      it "is valid with two adults and 20 children" do
        form.members_attributes = 20.times.map do |i|
          [i, required_attrs.merge(birthday: "1.1.2014")]
        end + [[21, required_attrs.merge(birthday: "1.1.2000")]]

        expect(form).to be_valid
        expect(form.members).to have(21).items
      end

      it "is invalid with 2 more adults as members" do
        form.members_attributes = 2.times.map do |i|
          [i, required_attrs.merge(birthday: "1.1.2000")]
        end
        expect(form).not_to be_valid
        expect(form.errors.full_messages).to eq ["In einer Familienmitgliedschaft sind maximal 2 Erwachsene inbegriffen."]
      end

      it "is invalid if second member reuses existing email" do
        form.members_attributes = [
          [0, required_attrs.merge(email: "acceptable@example.com")],
          [1, required_attrs.merge(email: "e.hillary@hitobito.example.com", birthday: "1.10.2014")]
        ]
        expect(form).not_to be_valid
        expect(form.members.second.errors.full_messages).to eq ["E-Mail (optional) ist bereits vergeben. Die E-Mail muss eindeutig sein pro Person."]
      end

      it "is invalid if second member reuses main_email in members" do
        form.members_attributes = [
          [0, required_attrs.merge(email: "acceptable@example.com")],
          [1, required_attrs.merge(email: "test@example.com", birthday: "1.10.2014")]
        ]
        expect(form).not_to be_valid
        expect(form.members.second.errors.full_messages).to eq ["E-Mail (optional) ist bereits vergeben. Die E-Mail muss eindeutig sein pro Person."]
      end

      it "is invalid if second member reuses first member email" do
        form.members_attributes = [
          [0, required_attrs.merge(email: "acceptable@example.com")],
          [1, required_attrs.merge(email: "acceptable@example.com", birthday: "1.10.2014")]
        ]
        expect(form).not_to be_valid
        expect(form.members.second.errors.full_messages).to eq ["E-Mail (optional) ist bereits vergeben. Die E-Mail muss eindeutig sein pro Person."]
      end
    end
  end
end
