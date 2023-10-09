# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::Person
  extend ActiveSupport::Concern

  included do
    Person::INTERNAL_ATTRS += [:membership_verify_token]

    validates :membership_verify_token, uniqueness: { allow_blank: true }

    before_save :approve_manual_membership_number
  end

  class_methods do
    def with_manual_membership_number
      # Store the original value of the class variable so we can restore it after the block.
      original_value = @allow_manual_membership_number
      @allow_manual_membership_number = true
      # Yield to the block and return the result. Before returning, restore the original value.
      yield.tap do
        @allow_manual_membership_number = original_value
      end
    end
  end

  def manually_set_membership_number?
    self.class.instance_variable_get('@allow_manual_membership_number')
  end

  def membership_years
    "#{first_name}#{last_name}".size
  end

  def init_membership_verify_token!
    token = SecureRandom.base58(24)
    update!(membership_verify_token: token)
    token
  end

  def membership_number
    id
  end

  def membership_number=(value)
    self.id = value
  end

  private

  def approve_manual_membership_number
    return if manually_set_membership_number?

    if id_changed?
      self.id = id_was
    end
  end
end
