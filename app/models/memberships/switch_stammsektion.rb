# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Memberships
  class SwitchStammsektion < JoinBase
    def initialize(...)
      super
      raise "terminated membership" if sac_membership.stammsektion_role&.terminated?
    end

    validate :assert_join_date

    def save
      super.tap do |success|
        update_primary_groups
      end
    end

    private

    def update_primary_groups
      affected_people.each do |person|
        person.reload # Unsure why this reload is necessary
        person.update!(primary_group: Groups::Primary.new(person).identify)
      end
    end

    def prepare_roles(person)
      old_role = existing_membership(person)

      # In case we can't locate the old membership role, we calculate the beitragskategorie
      # for the person as a fallback value.
      beitragskategorie = old_role&.beitragskategorie ||
        SacCas::Beitragskategorie::Calculator.new(person).calculate
      new_role = new_membership(person, beitragskategorie)

      [old_role, new_role].compact
    end

    def existing_membership(person)
      People::SacMembership.new(person).stammsektion_role.tap do |role|
        next unless role

        attrs = if join_date.future?
          {delete_on: [role.delete_on, join_date - 1.day].compact.min}
        else
          {delete_on: nil, deleted_at: (join_date - 1.day).end_of_day}
        end

        role.attributes = attrs
      end
    end

    def new_membership(person, beitragskategorie)
      attrs = if join_date.future?
        {convert_to: role_type, type: "FutureRole", convert_on: join_date}
      else
        {type: role_type, created_at: now, delete_on: now.end_of_year}
      end
      attrs[:person] = person

      # `Role#set_beitragskategorie` gets called in a before_validation callback, but
      # `Memberships::CommonApi#validate_roles` and `Memberships::CommonApi#save_roles`
      # first save the roles with `validate: false` to make the role validations working which
      # depend on persisted values. So we need to set the beitragskategorie here manually.
      attrs[:beitragskategorie] = beitragskategorie

      membership_group.roles.build(attrs)
    end

    def validate_family_main_person?
      person.sac_membership.family?
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
