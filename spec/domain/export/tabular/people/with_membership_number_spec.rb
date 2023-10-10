# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Export::Tabular::People::WithMembershipNumber do

  let(:person) { people(:mitglied) }

  shared_examples 'has membership_number' do

    it 'prepends WithMembershipNumber' do
      expect(tabular_class.ancestors).to include Export::Tabular::People::WithMembershipNumber

      expect(tabular_class.ancestors.index(Export::Tabular::People::WithMembershipNumber)).
        to be < tabular_class.ancestors.index(tabular_class)
    end

    subject { tabular_class.new([tabular_entry]) }

    it 'has the membership_number header' do
      expect(subject.attributes).to include :membership_number
    end

    it 'has the correct membership_number label' do
      expect(subject.attribute_labels[:membership_number]).to eq 'Mitglied-Nr'
    end

    it 'has the correct membership_number value' do
      row = subject.attributes.zip(subject.data_rows.first).to_h
      expect(row[:membership_number]).to eq person.membership_number
    end

  end

  [
    Export::Tabular::People::Households,
    Export::Tabular::People::PeopleAddress,
    Export::Tabular::People::PeopleFull
  ].each do |tabular_class|

    describe tabular_class do
      let(:tabular_class) { tabular_class }
      let(:tabular_entry) { people(:mitglied) }

      it_behaves_like 'has membership_number'
    end

  end

  [
    Export::Tabular::People::ParticipationsFull,
    Export::Tabular::People::ParticipationsHouseholds
  ].each do |tabular_class|

    describe tabular_class do
      let(:tabular_class) { tabular_class }
      let(:tabular_entry) { Fabricate(:event_participation, person: people(:mitglied)) }

      it_behaves_like 'has membership_number'
    end
  end
end
