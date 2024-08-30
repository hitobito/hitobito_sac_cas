# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  module Sektion
    class AdditionalMembership < Membership
      TARGET_ROLE_TYPE = Group::SektionsMitglieder::MitgliedZusatzsektion

      def initialize(row, group:, current_ability:)
        @row = row
        @group = group
        @current_ability = current_ability
      end

      def valid?
        @valid ||= role.valid?(:import)
      end

      def import!
        role.save!(context: :import)
      end

      private

      def build_role
        return Role.new unless person

        person.roles
          .where(group_id: @group&.id, type: TARGET_ROLE_TYPE.sti_name)
          .first_or_initialize.tap do |role|
          role.attributes = {
            beitragskategorie: BEITRAGSKATEGORIEN[row[:beitragskategorie]],
            start_on: joining_date,
            end_on: DEFAULT_END_ON,
            skip_mitglied_during_validity_period_validation: true
          }
        end
      end

      def joining_date
        parse_date(row[:joining_date])
      end

      def build_error_messages
        return "Person #{navision_id} existiert nicht" unless person

        role.errors.full_messages
          .flatten.compact.join(", ").tap do |messages|
            messages.prepend("#{self}: ") if messages.present?
          end
      end
    end
  end
end
