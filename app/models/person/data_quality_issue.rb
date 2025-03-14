# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# == Schema Information
#
# Table name: person_data_quality_issues
#
#  id         :bigint      not null, primary key
#  person_id  :integer     not null
#  attr       :string(255) not null
#  key        :string(255) not null
#  severity   :integer     not null
#  created_at :datetime    not null
#  updated_at :datetime    not null
#
# Indexes
#
#  index_person_data_quality_issues_on_person_id (person)
#  index_person_data_quality_issues_on_person_and_attribute_and_key (key) UNIQUE

class Person::DataQualityIssue < ApplicationRecord
  belongs_to :person

  enum severity: {info: 1, warning: 2, error: 3}

  validate :person_attribute_to_check
  validates :attr, :severity, presence: true
  validates :key, uniqueness: {scope: %i[person_id attr]}, presence: true

  def message
    I18n.t("activemodel.errors.models.person.data_quality_issue.message",
      attr: Person.human_attribute_name(attr),
      key: I18n.t(key,
        default: key,
        scope: "activemodel.errors.models.data_quality_issue.messages"))
  end

  private

  def person_attribute_to_check
    return if People::DataQualityChecker::ATTRIBUTES_TO_CHECK.include?(attr)

    errors.add(:attr, :invalid)
  end
end
