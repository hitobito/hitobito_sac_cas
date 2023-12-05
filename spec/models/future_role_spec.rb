# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require 'spec_helper'

describe FutureRole do
  context '#start_on' do
    it 'returns convert_on' do
      role = FutureRole.new(convert_on: 42.days.from_now.to_date)
      expect(role.start_on).to eq role.convert_on
    end
  end

  # [deleted_at&.to_date, archived_at&.to_date, delete_on].compact.min

  context '#end_on' do
    it 'returns end of year after convert_on' do
      role = FutureRole.new(convert_on: 1.year.from_now.to_date)
      expect(role.end_on).to eq role.convert_on.end_of_year
    end
  end
end
