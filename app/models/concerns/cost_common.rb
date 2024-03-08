# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module CostCommon
  extend ActiveSupport::Concern
  included do
    include Globalized
    translates :label

    validates :label, presence: true
    validates :code, uniqueness: true

    scope :list, -> { order(:code) }

    validates_by_schema
  end

  def to_s
    [code, label].join(" - ")
  end
end
