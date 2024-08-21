# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::PeopleManagersController
  def create
    super do
      household.add(new_person)
      household.valid? || raise(ActiveRecord::Rollback)
      household.save!
    end
  end

  def destroy
    super do |entry|
      household = entry.managed.household
      household.remove(entry.managed)
      household.save!
    end
  end

  private

  delegate :manager, :managed, to: :entry

  def household
    @household ||= household_person.household
  end

  def household_person
    @household_person ||= manager.household_key? ? manager : managed
  end

  def new_person
    @new_person ||= manager.household_key? ? managed : manager
  end
end
