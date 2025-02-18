# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# In the sac wagon, we allow only a predefined set of phone numbers with their distinct label.
# For those we always show the form fields, even if the records don't exist yet.
# To simplify the form handling, we define a `has_one` association for each predefined number.
module SacPhoneNumbers
  def self.prepended(base)
    PhoneNumber.predefined_labels.each do |label|
      phone_number_assoc = :"phone_number_#{label}"
      # rubocop:disable Rails/HasManyOrHasOneDependent (handled on has_many :phone_numbers)
      # rubocop:disable Rails/InverseOf (association not defined on opposite side)
      base.has_one phone_number_assoc, -> { where(label: label) },
        class_name: "PhoneNumber", as: :contactable
      # rubocop:enable Rails/HasManyOrHasOneDependent, Rails/InverseOf

      base.accepts_nested_attributes_for phone_number_assoc, allow_destroy: true
    end
  end
end
