# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# == Schema Information
#
# Table name: section_offerings
#
#  id         :bigint           not null, primary key
#  title      :text(65535)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null

class SectionOffering < ApplicationRecord
  has_and_belongs_to_many :sections,
    class_name: Group::Sektion.sti_name,
    association_foreign_key: :group_id

  translates :title, fallbacks_for_empty_translations: true

  validates :title, presence: true
  before_destroy :check_associated_sections

  default_scope { includes(:translations) }

  def to_s
    title
  end

  private

  # Callback to check if there are any associated sections
  def check_associated_sections
    if sections.exists?
      if sections.size == 1
        errors.add(:base, :"restrict_dependent_destroy.has_one", record: Group::Sektion.model_name.human)
      else
        errors.add(:base, :"restrict_dependent_destroy.has_many", record: Group::Sektion.model_name.human(count: sections.size))
      end
      throw(:abort)
    end
  end
end
