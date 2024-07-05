# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::PeopleManager
  extend ActiveSupport::Concern

  prepended do
    validate :assert_not_in_different_household
    validate :manager_is_adult
    validate :managed_is_child
  end

  private

  def assert_not_in_different_household
    return if manager.household_key == managed.household_key ||
      manager.household_key.nil? ||
      managed.household_key.nil?

    errors
      .add(:managed_id, :in_different_household, name: managed_name)
  end

  def manager_is_adult
    return if manager.nil? || SacCas::Beitragskategorie::Calculator.new(manager).adult?

    errors.add(:manager_id, :manager_is_not_adult, name: manager_name, age: manager.years)
  end

  def managed_is_child
    return if managed.nil?

    calculator = SacCas::Beitragskategorie::Calculator.new(managed)
    return if calculator.child? || calculator.pre_school_child?

    errors.add(:managed_id, :managed_is_not_child, name: managed_name, age: managed.years)
  end

  def managed_name
    managed.full_name
  end

  def manager_name
    manager.full_name
  end
end
