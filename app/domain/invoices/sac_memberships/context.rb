# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    class Context

      attr_reader :date

      def initialize(date)
        @date = date
      end

      def mid_year_discount
        @mid_year_discount ||= (100 - config.discount_percent(date)) / 100.0
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

    end
  end
end
