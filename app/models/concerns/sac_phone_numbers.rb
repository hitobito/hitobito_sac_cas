# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# In the sac wagon, we allow only a fixed set of phone numbers, one per
# ContactAccountCategory#key. For those we always show the form fields, even if
# the records don't exist yet. To simplify the form handling, we define a
# `has_one` association for each fixed slot.
module SacPhoneNumbers
  FIXED_SLOT_KEYS = %w[landline mobile].freeze

  def self.prepended(base)
    # contactable_type is static (known from base itself); the category_id
    # lookup is memoized (.category_id below) rather than baked in at boot, so
    # it still picks up categories seeded later (or fixtures/factories in
    # tests), while not re-querying on every single association access -- categories
    # are immutable reference data once seeded, so a lookup is never stale.
    contactable_type = base.base_class.sti_name

    FIXED_SLOT_KEYS.each do |key|
      phone_number_assoc = :"phone_number_#{key}"
      # rubocop:disable Rails/HasManyOrHasOneDependent (handled on has_many :phone_numbers)
      # rubocop:disable Rails/InverseOf (association not defined on opposite side)
      base.has_one phone_number_assoc,
        -> { where(category_id: SacPhoneNumbers.category_id(contactable_type, key)) },
        class_name: "PhoneNumber", as: :contactable
      # rubocop:enable Rails/HasManyOrHasOneDependent, Rails/InverseOf

      base.accepts_nested_attributes_for phone_number_assoc, allow_destroy: true
    end
  end

  def self.category_id(contactable_type, key)
    @category_ids ||= {}
    @category_ids[[contactable_type, key]] ||=
      ContactAccountCategory.for("PhoneNumber", contactable_type).pluck(:key, :id).to_h
    @category_ids[[contactable_type, key]][key]
  end
end
