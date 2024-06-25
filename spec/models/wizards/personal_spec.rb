# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe Wizards::Personal do
  def mitglied_role_class = Group::SektionsMitglieder::Mitglied
  def calculator = SacCas::Beitragskategorie::Calculator

  before do
    stub_const('PersonalWizard', Class.new(Wizards::Base) { include Wizards::Personal })
  end

  let(:opts) { { current_step: 0 } }
  subject(:wizard) { PersonalWizard.new(**opts) }

  it 'has person attribute' do
    expect(wizard.attribute_names).to include('person')
  end

  it 'validates presence of person' do
    expect(wizard).not_to be_valid
    expect(wizard.errors[:person]).to include("muss ausgefüllt werden")
  end

  it 'validates presence of membership_role' do
    wizard.person = Person.new
    expect(wizard).not_to be_valid
    expect(wizard.errors[:person]).to include("ist kein Mitglied")

    allow(wizard).to receive(:membership_role).and_return(roles(:mitglied))
    expect(wizard).to be_valid
  end

  describe '#membership_role' do
    it 'returns nil if person is nil' do
      expect(opts[:person]).to be_nil # check assumed precondition
      expect(wizard.membership_role).to be_nil
    end

    it 'returns the current membership role of the person if one exists' do
      opts[:person] = people(:mitglied)
      expect(wizard.membership_role).to eq roles(:mitglied)
    end

    it 'returns the latest expired membership role if no current role exists' do
      person = people(:mitglied)
      opts[:person] = person

      latest_role = roles(:mitglied).tap do |role|
        role.update!(deleted_at: role.created_at + 1.year)
      end

      # create an even older deleted role
      mitglied_role_class.create!(
        person: person,
        group: latest_role.group,
        created_at: latest_role.created_at - 2.years,
        deleted_at: latest_role.created_at - 1.year
      )

      expect(wizard.membership_role).to eq(latest_role)
    end
  end

  describe '#family_membership?' do
    it 'returns false if membership role is nil' do
      allow(wizard).to receive(:membership_role).and_return(nil)
      expect(wizard.family_membership?).to eq false
    end

    it 'returns false if membership role is not a family membership' do
      allow(wizard).to receive(:membership_role) do
        mitglied_role_class.new(beitragskategorie: calculator::CATEGORY_YOUTH)
      end
      expect(wizard.family_membership?).to eq false
    end

    it 'returns true if membership role is a family membership' do
      allow(wizard).to receive(:membership_role) do
        mitglied_role_class.new(beitragskategorie: calculator::CATEGORY_FAMILY)
      end
      expect(wizard.family_membership?).to eq true
    end
  end

  describe '#family_main_person?' do
    it 'returns false if person is nil' do
      expect(wizard.family_main_person?).to eq false
    end

    it 'returns false if person is not a family main person' do
      wizard.person = Person.new(sac_family_main_person: false)
      expect(wizard.family_main_person?).to eq false
    end

    it 'returns true if person is a family main person' do
      wizard.person = Person.new(sac_family_main_person: true)
      expect(wizard.family_main_person?).to eq true
    end
  end
end
