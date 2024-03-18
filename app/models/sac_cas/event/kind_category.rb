# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: event_kind_categories
#
#  id             :bigint           not null, primary key
#  deleted_at     :datetime
#  label          :string(255)
#  order          :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  cost_center_id :bigint           not null
#  cost_unit_id   :bigint           not null
#
# Indexes
#
#  index_event_kind_categories_on_cost_center_id                   (cost_center_id)
#  index_event_kind_categories_on_cost_unit_id                     (cost_unit_id)
#
module SacCas::Event::KindCategory
  extend ActiveSupport::Concern

  prepended do
    belongs_to :cost_center
    belongs_to :cost_unit
  end
end
