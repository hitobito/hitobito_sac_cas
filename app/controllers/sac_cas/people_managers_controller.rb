# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::PeopleManagersController
  def create
    super do
      household.valid? || raise(ActiveRecord::Rollback)
      household.persist!
    end
  end

  def destroy
    super do |entry|
      Person::Household.new(entry.managed, current_ability).leave.persist!
    end
  end

  private

  delegate :manager, :managed, to: :entry

  def household
    @household ||= build_household
  end

  def build_household
    household_person, new_person = manager.household_key? ? [manager, managed] : [managed, manager]
    Person::Household.new(household_person, current_ability, new_person).tap(&:assign)
  end
end
