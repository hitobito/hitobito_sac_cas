# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class SwitchStammsektion < JoinBase

    def initialize(...)
      super
      raise 'terminated membership' if sac_membership.roles.any?(&:terminated?)
    end

    validate :assert_join_date

    private

    def prepare_roles(person)
      [
        People::SacMembership.new(person).roles.each do |role|
          role.attributes = precursor_role_attrs(role)
        end,
        membership_group.roles.build(role_attrs.merge(person: person))
      ].flatten.compact
    end

    def role_attrs
      if join_date.future?
        { convert_to: role_type, type: 'FutureRole', convert_on: join_date }
      else
        { type: role_type, created_at: now, delete_on: now.end_of_year }
      end
    end

    def precursor_role_attrs(role)
      if join_date.future?
        { delete_on: [role.delete_on, join_date - 1.day].compact.min }
      else
        { delete_on: nil, deleted_at: (join_date - 1.day).end_of_day }
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
