# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class CourseCompensationCategory < ApplicationRecord
  include I18nEnums
  include CapitalizedDependentErrors

  has_many :course_compensation_rates, dependent: :restrict_with_error
  translates :name_leader, :name_assistant_leader

  KINDS = %w[day flat budget]
  i18n_enum :kind, KINDS

  def to_s
    "#{short_name} (#{kind_label})"
  end
end