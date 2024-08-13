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

  validate :person_attribute_exists
  validates :attr, :key, :severity, presence: true

  def severity=(value)
    super(self.class.severities.keys.index(value.to_s)&.next)
  end

  private

  def person_attribute_exists
    errors.add(:attr, :invalid) unless Person.column_names.include?(attr)
  end
end
