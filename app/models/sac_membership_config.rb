# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class SacMembershipConfig < ApplicationRecord
  validates_by_schema

  attr_readonly :valid_from

  # date format: 1.7., 1.10.
  with_options format: { with: /\A[0123]?\d\.[012]?\d\.\z/ } do
    validates :discount_date_1
    validates :discount_date_2
    validates :discount_date_3
  end

  def to_s
    valid_from
  end
end
