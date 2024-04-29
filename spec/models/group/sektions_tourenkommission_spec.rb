# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe Group::SektionsTourenkommission do
  let(:group) { Fabricate.build(Group::SektionsTourenkommission.sti_name) }

  describe Group::SektionsTourenkommission::Tourenleiter do
    let(:person) { people(:tourenchef) }
    let(:kind) { qualification_kinds(:snowboard_leader) }
    subject(:role) { Fabricate.build(described_class.to_s, group: group, person: person) }

    it 'is invalid without qualifications' do
      expect(role).not_to be_valid
      expect(role.errors.full_messages).to eq [
        'Person muss mindestens eine aktive Qualifikation besitzen.'
      ]
    end

    it 'is invalid with expired qualification' do
      person.qualifications.create!(qualification_kind: kind, start_at: 2.years.ago, finish_at: Time.zone.yesterday)
      expect(role).not_to be_valid
      expect(role.errors.full_messages).to eq [
        'Person muss mindestens eine aktive Qualifikation besitzen.'
      ]
    end

    it 'is valid with active non expiring qualification' do
      person.qualifications.create!(qualification_kind: kind, start_at: 2.years.ago).tap do |q|
        q.update_columns(finish_at: nil)
      end
      expect(role).to be_valid
    end

    it 'is valid with active expiring qualification' do
      person.qualifications.create!(qualification_kind: kind, start_at: 2.years.ago, finish_at: 1.day.from_now)
      expect(role).to be_valid
    end
  end
end
