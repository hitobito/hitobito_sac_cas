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

      self.description = "Rebuild family memberships whose membership invoice was paid or " \
        "correct end_ons so that it doesnt even happen, SCSD-10329 & HIT-1728"

      def run(year: Date.current.year)
        @year = year
        affected_family_ids.each do |family_id|
          Person.transaction { correct_family(family_id) }
        rescue => e
          puts error("family #{family_id}: #{e.class}: #{e.message}")
        end
      end

      private

      attr_reader :year

      def early_end_on = Date.new(year, 6, 30)

      def late_end_on = Date.new(year, 7, 1)

      # Staggered membership extensions left some family members one day behind.
      def end_on_range = early_end_on..late_end_on

      def new_end_on = late_end_on.end_of_year

      def correct_family(family_id)
        person_ids = family_roles(family_id).distinct.pluck(:person_id)
        payer = Person.where(id: person_ids).find_by(id: payed_invoices.select(:person_id))

        if payer
          rebuild_family(family_id, payer, person_ids - [payer.id])
        else
          equalise_end_on(family_id)
        end
      end

      def rebuild_family(family_id, main_person, member_ids)
        membership = main_person.sac_membership
        if membership.active?
          if membership.stammsektion_role.beitragskategorie.family?
            return puts warning("family #{family_id}: skipped, #{main_person.id} has an active " \
              "family membership")
          end

          # Depending on the code version that processed the payment, it either created a
          # solo membership for the main person or failed and left the family roles expired.
          destroy_solo_membership(membership)
        end

        members = family_members(member_ids)
        restore_household(main_person, members)
        ([main_person] + members).each { extend_roles(_1) }

        puts success("family #{family_id}: restored #{members.size + 1} people " \
          "with main person #{main_person.id}")
      end

      def family_members(member_ids)
        members = Person.where(id: member_ids).to_a
        raise "no family members found" if members.empty?

        active = members.select { _1.sac_membership.active? }
        raise "family members with active membership: #{active.map(&:id).join(", ")}" if active.any?

        members
      end

      def destroy_solo_membership(membership)
        membership.zusatzsektion_roles.each { hard_destroy_role(_1) }
        hard_destroy_role(membership.stammsektion_role)
      end

      def restore_household(main_person, members)
        household = ::Household.new(main_person,
          maintain_sac_family: false, validate_members: false)
        members.reduce(household, :add).save!(context: :create)
        household.set_family_main_person!
      end

      def extend_roles(person)
        membership = ::People::SacMembership.new(person, date: early_end_on)

        [
          membership.stammsektion_role,
          *membership.zusatzsektion_roles.reject(&:terminated?),
          *membership.membership_prolongable_roles.reject(&:terminated?)
        ].each { _1.update!(end_on: new_end_on) }
      end

      # Aligns the family so that a later payment can restore the household.
      def equalise_end_on(family_id)
        roles = family_roles(family_id).where(end_on: early_end_on)
        return if roles.none?

        roles.find_each do |role|
          role.end_on = late_end_on
          role.save(validate: false)
        end
        puts info("family #{family_id}: not paid, equalised end_on")
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
          object_changes: role.attributes.except("updated_at")
            .transform_values { |v| [v, nil] }.to_yaml
        )

        role.really_destroy!
      end

      def affected_family_ids
        family_roles
          .group(:family_id)
          .having("MAX(end_on) = ?", late_end_on)
          .having("MIN(start_on) <= ?", late_end_on.beginning_of_year)
          .pluck(:family_id)
      end

      def family_roles(family_id = nil)
        roles = Role.with_inactive
          .where(beitragskategorie: :family, terminated: false, end_on: end_on_range)
          .where.not(family_id: nil)
        family_id ? roles.where(family_id:) : roles
      end

      def payed_invoices
        ExternalInvoice::SacMembership.payed.where(year:)
      end
    end
  end
end

# rubocop:enable Rails/Output
