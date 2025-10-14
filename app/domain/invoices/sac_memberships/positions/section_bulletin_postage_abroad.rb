# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class SectionBulletinPostageAbroad < Base
        def active?
          member.living_abroad? && section_bulletin? && positive_porto_amount? && paying_person?
        end

        def gross_amount
          return 0 if section_fee_exemption?

          section.bulletin_postage_abroad
        end

        def creditor
          section
        end

        private

        def positive_porto_amount? = section.bulletin_postage_abroad.to_i.positive?

        # rubocop:todo Layout/LineLength
        def section_bulletin? = section_bulletin_mailing_list && !section_bulletin_mailing_list&.subscriptions&.exists?(
          # rubocop:enable Layout/LineLength
          subscriber: member.person, excluded: true)

        def section_bulletin_mailing_list = MailingList.find_by(
          # rubocop:todo Layout/LineLength
          internal_key: SacCas::MAILING_LIST_SEKTIONSBULLETIN_PAPER_INTERNAL_KEY, group_id: section.id
          # rubocop:enable Layout/LineLength
        )
      end
    end
  end
end
