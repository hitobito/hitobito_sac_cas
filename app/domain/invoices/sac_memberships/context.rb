# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class Context
      attr_reader :date, :custom_discount

      def initialize(date, custom_discount: nil)
        @date = date
        @custom_discount = custom_discount  # between 0 and 100
      end

      def fetch_section(role)
        @sections ||= {}
        @sections[role.layer_group.id] ||= Section.new(role.layer_group, date)
      end

      def config
        @config ||= SacMembershipConfig.active(date)
      end

      def sac
        @sac ||= Group.root
      end

      def sac_magazine_mailing_list
        # rubocop:todo Layout/LineLength
        @sac_magazine_mailing_list ||= MailingList.find_by(internal_key: SacCas::MAILING_LIST_DIE_ALPEN_PAPER_INTERNAL_KEY)
        # rubocop:enable Layout/LineLength
      end

      def people_with_membership_years
        Person
          .with_membership_years("people.*", Date.new(date.year - 1, 12, 31))
          .preload_roles_unscoped
      end

      def discount_factor
        @discount_factor ||=
          if custom_discount
            (100 - custom_discount) / 100.0
          else
            mid_year_discount_factor
          end
      end

      def mid_year_discount_factor
        @mid_year_discount_factor ||= (100 - config.discount_percent(date)) / 100.0
      end
    end
  end
end
