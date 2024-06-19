# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class SwitchStammsektion < MemberJoinSectionBase

    validate :assert_join_date

    private

    def save_roles
      Role.transaction do
        terminate_then_create_roles_for(affected_people)
      end
    end

    # Terminating and creating one by one works best with for existing validations
    def terminate_then_create_roles_for(people)
      people.map do |person|
        terminate_existing_roles!(person)
        roles.select { |r| r.person_id == person.id }.each(&:save!)
      end
    end

    def terminate_existing_roles!(person)
      scope = role_type.where(person_id: person.id)

      if join_date.future?
        scope.where(delete_on: nil)
             .or(scope.where(delete_on: now.end_of_year..))
             .update_all(delete_on: now.end_of_year) # rubocop:disable Rails/SkipsModelValidations

      else
        scope.update_all(deleted_at: now.yesterday.end_of_day) # rubocop:disable Rails/SkipsModelValidations

      end
    end

    def prepare_roles(person)
      membership_group.roles.build(role_attrs.merge(person: person))
    end

    def role_attrs
      if join_date.future?
        { convert_to: role_type, type: 'FutureRole', convert_on: join_date }
      else
        { type: role_type, created_at: now, delete_on: now.end_of_year }
      end
    end

    def validate_family_main_person?
      person.sac_family_member?
    end

    def assert_join_date
      unless valid_dates.include?(join_date)
        errors.add(:join_date, :invalid)
      end
    end

    def valid_dates
      [now.to_date, now.next_year.beginning_of_year.to_date]
    end

    def membership_group
      @membership_group ||= join_section.children.find_by(type: Group::SektionsMitglieder.sti_name)
    end

    def role_type
      Group::SektionsMitglieder::Mitglied
    end
  end
end
