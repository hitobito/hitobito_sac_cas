# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::PhoneNumber
  extend ActiveSupport::Concern

  included do
    after_create :check_data_quality
    after_destroy :check_data_quality

    validates :category,
      inclusion: {in: -> { ContactAccountCategory.where(key: SacPhoneNumbers::FIXED_SLOT_KEYS) }}
    validates :category_id, uniqueness: {scope: [:contactable_type, :contactable_id]}
  end

  private

  def check_data_quality
    # prevent running the check twice
    # rubocop:todo Layout/LineLength
    return if !contactable.is_a?(Person) || People::DataQualityChecker.attributes_to_check_changed?(contactable)
    # rubocop:enable Layout/LineLength

    contactable.phone_numbers.reload
    People::DataQualityChecker.new(contactable).check_data_quality
  end
end
