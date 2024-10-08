# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: cost_units
#
#  id         :bigint           not null, primary key
#  code       :string(255)      not null
#  label      :string(255)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#
# Indexes
#
#  index_cost_units_on_code  (code) UNIQUE
#
class CostUnit < ApplicationRecord
  include CostCommon
end
