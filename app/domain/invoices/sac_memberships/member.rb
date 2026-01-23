# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    Membership = Data.define(:section, :beitragskategorie, :main) do
      delegate :family?, :youth?, :adult?, to: :beitragskategorie
    end

    class Member
      attr_reader :person, :context, :sac_membership

      delegate :id, :to_s, :language, :sac_family_main_person?, :living_abroad?, to: :person
      delegate :date, :sac_magazine_mailing_list, to: :context
      delegate :zusatzsektion_roles,
        :neuanmeldung_nv_stammsektion_roles, :neuanmeldung_nv_zusatzsektion_roles,
        :sektion_ehrenmitglied?, :sektion_beguenstigt?,
        to: :sac_membership

      # Person model
      def initialize(person, context)
        @person = person
        @sac_membership = People::SacMembership.new(person, date: context.date, in_memory: true)
        @context = context
      end

      def age
        @age ||= person.years(Date.new(date.year, 12, 31))
      end

      def membership_years
        return 0 if person.new_record? || person.roles.empty?
        # person must have been loaded with .with_membership_years(Date.new(date.year - 1, 12, 31))
        # rubocop:todo Layout/LineLength
        # so membership years correspond to the value that will be reached at the end of the reference year,
        # rubocop:enable Layout/LineLength
        # even if roles are not yet prolonged until the end of this year.
        # This value is off by one for the first year, but as it is only used for reductions that
        # are granted after many years, it does not matter.
        person.membership_years + 1
      end

      def membership_from_role(role, main: nil)
        main = role == stammsektion_role if main.nil?
        Membership.new(role.layer_group, role.beitragskategorie, main)
      end

      def active_memberships
        return [] unless stammsektion_role

        [membership_from_role(stammsektion_role)] +
          zusatzsektion_roles.map { |r| membership_from_role(r) }.sort_by { |m| m.section.to_s }
      end

      def stammsektion
        stammsektion_role&.layer_group
      end

      def stammsektion_role
        return @stammsektion_role if defined?(@stammsektion_role)

        @stammsektion_role = sac_membership.stammsektion_role
      end

      def sac_ehrenmitglied?
        return @sac_ehrenmitglied if defined?(@sac_ehrenmitglied)

        @sac_ehrenmitglied = sac_membership.sac_ehrenmitglied?
      end

      def sac_magazine?
        return @sac_magazine if defined?(@sac_magazine)

        # Explicitly check for exclusion because `subscribed?` filters for roles active today,
        # not at `context.date`.
        # Furthermore, Neuanmeldung roles would not count as subscribed either, even though
        # they will always obtain the magazine initially.
        @sac_magazine =
          !sac_magazine_mailing_list
            .subscriptions
            .exists?(subscriber: person, excluded: true)
      end

      def paying_person?(beitragskategorie)
        !beitragskategorie.family? || sac_family_main_person?
      end

      def family_members
        person.household_people.select { |p| sac_mitgliedschaft?(p) }.sort_by(&:id)
      end

      private

      def sac_mitgliedschaft?(person)
        People::SacMembership.new(person, date:).active?
      end
    end
  end
end
