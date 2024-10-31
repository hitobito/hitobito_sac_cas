# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: course_compensation_categories
#
#  id                    :bigint           not null, primary key
#  description           :string(255)
#  kind                  :string(255)      default("day"), not null
#  name_assistant_leader :string(255)      not null
#  name_leader           :string(255)      not null
#  short_name            :string(255)      not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_course_compensation_categories_on_short_name  (short_name) UNIQUE
#
class CourseCompensationCategory < ApplicationRecord
  include I18nEnums
  include CapitalizedDependentErrors

  validates_by_schema

  has_many :course_compensation_rates, dependent: :restrict_with_error
  has_and_belongs_to_many :event_kinds, association_foreign_key: :event_kind_id, class_name: "Event::Kind"
  translates :name_leader, :name_assistant_leader

  KINDS = %w[day flat budget]
  i18n_enum :kind, KINDS

  scope :list, -> { includes([:translations]).order(:short_name) }

  def to_s
    "#{short_name} (#{kind_label})"
  end

  def current_compensation_rate(cutoff = Time.zone.now)
    course_compensation_rates.where(
      "(:cutoff >= valid_from) AND (valid_to IS NULL OR valid_to >= :cutoff)",
      cutoff: cutoff
    ).first
  end
end
