# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Invoices
  module SacMemberships
    module Positions
      class ServiceFee < Base

        def active?
          paying_person? ||
            person.additional_membership_roles.any? { |r| !r.beitragskategorie.family? }
        end

        def amount
          config.service_fee
        end

        def debitor
          section
        end

      end
    end
  end
end
