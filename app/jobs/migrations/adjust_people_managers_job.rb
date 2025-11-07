# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  # A one-off job to add missing people manger entries for children and non-main adults.
  class AdjustPeopleManagersJob < BaseJob
    def perform
      main_people.find_each(batch_size: 100) do |main|
        adjust_managers(main)
      end
    end

    private

    def main_people
      Person.where(sac_family_main_person: true).where.not(household_key: ["", nil])
    end

    def adjust_managers(main_person)
      Person.transaction do
        main_person.household.create_missing_people_managers(main_person)
      end
    end
  end
end
