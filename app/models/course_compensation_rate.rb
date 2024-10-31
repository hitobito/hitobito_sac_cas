# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: course_compensation_rates
#
#  id                              :bigint           not null, primary key
#  rate_assistant_leader           :decimal(7, 2)    not null
#  rate_leader                     :decimal(7, 2)    not null
#  valid_from                      :date             not null
#  valid_to                        :date
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  course_compensation_category_id :bigint           not null
#
# Indexes
#
#  course_compensation_rate_on_category_id  (course_compensation_category_id)
#

class CourseCompensationRate < ApplicationRecord
  validates_by_schema
  belongs_to :course_compensation_category
  scope :list, -> { includes(course_compensation_category: [:translations]).order(valid_from: :DESC).order("course_compensation_categories.short_name ASC") }
  scope :at, ->(date) { where("(:date >= valid_from) AND (valid_to IS NULL OR valid_to >= :date)", date: date) }
  validate :assert_category_uniqueness_during_validity_period

  def assert_category_uniqueness_during_validity_period
    scope = CourseCompensationRate.where(course_compensation_category: course_compensation_category)
    if scope
        .where.not(id: id)
        .where(
          "(:valid_to IS NULL OR valid_from <= :valid_to) AND (valid_to IS NULL OR valid_to >= :valid_from)",
          valid_from: valid_from,
          valid_to: valid_to
        )
        .any?
      errors.add(:course_compensation_category_id, :uniqueness_during_validity_period)
    end
  end

  def to_s
    "#{valid_from} - #{valid_to} #{course_compensation_category}"
  end
end
