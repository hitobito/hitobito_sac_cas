# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::Person
  extend ActiveSupport::Concern

  included do

    MIN_GENERATED_MEMBERSHIP_NUMBER = 500_000
    Person::INTERNAL_ATTRS += [:membership_verify_token]

    validates :membership_verify_token, uniqueness: { allow_blank: true }

    attr_readonly :membership_number

    before_validation :set_membership_number, if: :new_record?

    # just make sure membership number is in a defined range
    validates :membership_number, inclusion: 100000..999999

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

  def membership_years
    "#{first_name}#{last_name}".size
  end

  def init_membership_verify_token!
    token = SecureRandom.base58(24)
    update!(membership_verify_token: token)
    token
  end

  def next_membership_number
    max = Person.maximum(:membership_number)

    if max.nil?
      next_number = MIN_GENERATED_MEMBERSHIP_NUMBER
    elsif max >= MIN_GENERATED_MEMBERSHIP_NUMBER
      next_number = max + 1
    end
  end

  private

  def set_membership_number
    return if manually_set_membership_number?

    self.membership_number = next_membership_number
  end

  def manually_set_membership_number?
    self.class.instance_variable_get('@allow_manual_membership_number')
  end
end
