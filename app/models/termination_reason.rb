# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class TerminationReason < ApplicationRecord
  validates_by_schema

  has_many :roles

  translates :text, fallbacks_for_empty_translations: true
  validates :text, presence: true

  def to_s
    text.inspect
  end
end
