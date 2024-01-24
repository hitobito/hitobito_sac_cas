# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe People::Neuanmeldungen::Promoter::NoDuplicateCondition do
  context '::satisfied?' do
    let(:role) { roles(:mitglied) }

    subject { described_class.new(role) }

    before { Person.update_all(created_at: 1.day.ago) }

    it 'is true if person has no duplicate' do
      expect(role.person.person_duplicates).to be_empty

      expect(subject.satisfied?).to eq true
    end

    it 'is false if person was created less than MINIMUM_PERSON_RECORD_AGE.ago' do
      timestamp = People::Neuanmeldungen::Promoter::
          NoDuplicateCondition::MINIMUM_PERSON_RECORD_AGE.ago + 1.minute
      role.person.update!(created_at: timestamp)

      expect(subject.satisfied?).to eq false
    end

    it 'is false if person has duplicate' do
      PersonDuplicate.create!(person_1: role.person, person_2: Fabricate(:person))

      expect(subject.satisfied?).to eq false
    end
  end
end
