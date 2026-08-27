# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

# rubocop:disable Rails/Output

module TTY
  module Memberships
    class RebuildFamilyMemberships
      prepend TTY::Command

      self.description = "Rebuild family memberships that were mistakenly reactivated as solo memberships or correct end_ons so that it doesnt even happen, SCSD-10329"

      def run
        main_family_people_with_accidental_solo_membership.each do |person|
          reactivate_membership_roles(person)
        end

        roles_to_just_correct_end_on.find_each do |role|
          role.end_on = late_end_on_date
          role.save(validate: false)
        end
      end

      private

      def reactivate_membership_roles(main_person)
        main_person.sac_membership.zusatzsektion_roles.each { hard_destroy_role(_1) }
        hard_destroy_role(main_person.sac_membership.stammsektion_role)

        restore_household(main_person)

        ([main_person] + family_people(main_person)).each do |person|
          past_membership = ::People::SacMembership.new(person, date: early_end_on_date)
          if past_membership.active?
            begin
              past_membership.stammsektion_role.update!(end_on: Time.zone.today.end_of_year)
              past_membership.zusatzsektion_roles.each { _1.update!(end_on: Time.zone.today.end_of_year) }
            rescue ActiveRecord::RecordInvalid => e
              require 'pry'; binding.pry unless $pstop
            end
          end
        end
      end

      def restore_household(main_person)
        restored_household = ::Household.new(main_person, maintain_sac_family: false, validate_members: false)
        family_members = family_people(main_person) or raise
        family_members.reduce(restored_household, :add).save!(context: :create)
        restored_household.set_family_main_person!
      end

      def family_people(main_person)
        family_id = ::People::SacMembership.new(main_person, date: early_end_on_date).stammsektion_role.family_id

        Person.where(id: Role.with_inactive.where(family_id:, end_on: early_end_on_date).where.not(person_id: main_person.id).select(:person_id))
      rescue
        require 'pry'; binding.pry unless $pstop
      end

      def hard_destroy_role(role)
        PaperTrail::Version.create!(
          item_type: "Role",
          item_id: 0,
          event: "destroy",
          main_type: "Person",
          main_id: role.person_id,
          item_label: role.to_s,
          created_at: Time.current,
          item_subtype: role.type,
          whodunnit: self.class.name,
          mutation_id: PaperTrail.request.controller_info[:mutation_id],
          object_changes: role.attributes.except("updated_at").transform_values { |v| [v, nil] }.to_yaml
        )

        role.really_destroy!
      end

      def main_family_people_with_accidental_solo_membership
        with_membership = Group::SektionsMitglieder::Mitglied.with_inactive.where(
          person_id: Role.with_inactive.where(family_id: affected_family_ids, end_on: early_end_on_date..late_end_on_date).select(:person_id),
          start_on: Date.new(2026, 1, 1).., end_on: Date.current..
        ).where.not(beitragskategorie: :family).select(:person_id)

        Person.where(id: with_membership)
      end

      def roles_to_just_correct_end_on
        Role.with_inactive.where(family_id: affected_family_ids).where(end_on: early_end_on_date)
      end

      def affected_family_ids
        @affected_family_ids ||= Role.with_inactive
          .where.not(family_id: nil)
          .where(beitragskategorie: :family)
          .where(end_on: Date.new(2026, 1, 1)..)
          .group(:family_id)
          .having("MIN(end_on) = ?", early_end_on_date)
          .having("MAX(end_on) = ?", late_end_on_date)
          .select(:family_id)
      end

      def early_end_on_date
        Date.new(2026, 6, 30)
      end

      def late_end_on_date
        Date.new(2026, 7, 1)
      end
    end
  end
end

# rubocop:enable Rails/Output
