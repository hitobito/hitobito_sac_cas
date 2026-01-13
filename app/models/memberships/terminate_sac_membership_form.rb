# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Memberships::TerminateSacMembershipForm < Memberships::TerminationForm
  attribute :subscribe_newsletter, :boolean, default: false
  attribute :subscribe_fundraising_list, :boolean, default: false
  attribute :data_retention_consent, :boolean, default: false
  attribute :entry_fee_consent, :boolean

  validates :entry_fee_consent, acceptance: true
  validate :assert_household_valid_after_remove, unless: :sac_family_main_person?

  def initialize(terminate_on_values, person)
    @person = person
    @household = Household.new(person)
    super(terminate_on_values)
  end

  def attributes_for_operation
    super.except(:entry_fee_consent)
  end

  private

  attr_reader :person, :household

  delegate :sac_family_main_person?, to: :person

  def assert_household_valid_after_remove
    household.remove(person)
    if household.members.many? && !household.valid?
      household.errors.full_messages.each do |message|
        errors.add(:base, message.gsub(/Members\[\d+\]\s/, "").upcase_first)
      end
    end
  end
end
