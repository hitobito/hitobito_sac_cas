# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require 'spec_helper'

describe SacMembershipConfig do

  let(:config) { sac_membership_configs(:'2024') }

  it 'validates special discount date format' do
    config.discount_date_1 = '1.1'
    config.discount_date_2 = '10'
    config.discount_date_3 = '10.9.'

    expect(config).not_to be_valid

    error_keys = config.errors.keys
    expect(error_keys.count).to eq(2)
    expect(error_keys).to include(:discount_date_1)
    expect(error_keys).to include(:discount_date_2)
    expect(error_keys).not_to include(:discount_date_3)
  end

end
