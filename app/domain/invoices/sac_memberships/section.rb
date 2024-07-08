# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class Section
      attr_reader :group, :date

      delegate :id, :to_s, to: :group
      delegate_missing_to :config

      def initialize(group, date)
        @group = group
        @date = date
      end

      def reduction?(member) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        if reduction_required_membership_years.to_i.positive? &&
            reduction_required_age.to_i.positive?
          member.membership_years >= reduction_required_membership_years &&
            member.age >= reduction_required_age
        elsif reduction_required_membership_years.to_i.positive?
          member.membership_years >= reduction_required_membership_years
        elsif reduction_required_age.to_i.positive?
          member.age >= reduction_required_age
        else
          false
        end
      end

      # Is the member exempt from fees of this section?
      def section_fee_exemption?(member)
        member.sac_honorary_member? ||
          (section_fee_exemption_for_honorary_members && member.section_honorary_member?(self)) ||
          (section_fee_exemption_for_benefited_members && member.section_benefited_member?(self))
      end

      # Is the member exempt from fees of the sac zentralverband?
      def sac_fee_exemption?(member)
        member.sac_honorary_member? ||
          (sac_fee_exemption_for_honorary_members && member.section_honorary_member?(self)) ||
          (sac_fee_exemption_for_benefited_members && member.section_benefited_member?(self))
      end

      def huts?
        return @huts if defined?(@huts)

        @huts = group.descendants.without_deleted.exists?(type: Group::SektionsHuette.sti_name)
      end

      def config
        @config ||= group.sac_section_membership_configs.active(date) ||
          raise("No sac section membership config for #{group} in #{date.year}")
      end
    end
  end
end
