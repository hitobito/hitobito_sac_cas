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

    validates :label,
      inclusion: {in: PhoneNumber.predefined_labels},
      uniqueness: {scope: [:contactable_type, :contactable_id]},
      allow_blank: false
  end

  private

  def normalize_label
    # NOOP
    # We do not normalize phone number labels as they are predefined and the user
    # cannot enter arbitrary labels.
  end

  def check_data_quality
    # prevent running the check twice
    # rubocop:todo Layout/LineLength
    return if !contactable.is_a?(Person) || People::DataQualityChecker.attributes_to_check_changed?(contactable)
    # rubocop:enable Layout/LineLength

    contactable.phone_numbers.reload
    People::DataQualityChecker.new(contactable).check_data_quality
  end
end
